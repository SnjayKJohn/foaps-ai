from typing import List

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models.zomato_item import ZomatoItem


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
