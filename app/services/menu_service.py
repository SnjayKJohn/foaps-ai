from typing import List

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models.zomato_item import ZomatoItem
from app.models.zomato_customization import ZomatoItemGroup, ZomatoItemGroupChoice, ZomatoItemVariant


def search_by_names(db: Session, merchant_id: int, names: List[str]) -> List[ZomatoItem]:
    """Step 2: fuzzy-search the DB for each extracted item name using pg_trgm."""
    seen_ids: set = set()
    results: List[ZomatoItem] = []

    for name in names:
        matches = (
            db.query(ZomatoItem)
            .filter(
                ZomatoItem.location_id == merchant_id,
                ZomatoItem.item_is_active == 1,
                ZomatoItem.item_in_stock == 1,
                or_(
                    func.similarity(ZomatoItem.item_name, name) > 0.15,
                    ZomatoItem.item_name.ilike(f"%{name}%"),
                    ZomatoItem.item_short_description.ilike(f"%{name}%"),
                    ZomatoItem.item_long_description.ilike(f"%{name}%"),
                ),
            )
            .order_by(func.similarity(ZomatoItem.item_name, name).desc())
            .limit(10)
            .all()
        )
        for item in matches:
            if item.id not in seen_ids:
                seen_ids.add(item.id)
                results.append(item)

    return results


def get_item_customizations(db: Session, item_id: int) -> dict:
    """Fetch variants and item groups (with choices) for a menu item.

    Returns a dict with has_customizations, variants, and groups.
    Only active, non-deleted variants are included.
    Only groups with at least one choice are included.
    """
    variants = (
        db.query(ZomatoItemVariant)
        .filter(
            ZomatoItemVariant.zomato_item_id == item_id,
            ZomatoItemVariant.is_active.is_(True),
            ZomatoItemVariant.deleted_at.is_(None),
        )
        .all()
    )

    groups = (
        db.query(ZomatoItemGroup)
        .filter(ZomatoItemGroup.zomato_item_id == item_id)
        .all()
    )

    enriched_groups = []
    has_required_group = False
    for group in groups:
        choices = (
            db.query(ZomatoItemGroupChoice)
            .filter(ZomatoItemGroupChoice.zomato_item_group_id == group.id)
            .all()
        )
        if not choices:
            continue
        if (group.min_selection or 0) > 0:
            has_required_group = True
        enriched_groups.append(
            {
                "id": group.id,
                "name": group.name or "",
                "min_selection": group.min_selection or 0,
                "max_selection": group.max_selection or 1,
                "choices": [
                    {
                        "id": c.id,
                        "name": c.name or "",
                        "price": c.price or 0,
                    }
                    for c in choices
                ],
            }
        )

    variant_list = [
        {
            "id": v.id,
            "name": v.name or "",
            "unit_price": v.unit_price or 0,
        }
        for v in variants
    ]

    has_customizations = bool(variant_list) or has_required_group

    return {
        "has_customizations": has_customizations,
        "variants": variant_list,
        "groups": enriched_groups,
    }
