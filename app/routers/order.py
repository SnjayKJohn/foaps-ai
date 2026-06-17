from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.order import AmbiguousItem, OrderRequest, OrderResponse, SuggestedItem
from app.services import ai_service, menu_service

router = APIRouter(prefix="/order", tags=["order"])

_OUT_OF_SCOPE_MESSAGE = (
    "I can help you place an order or suggest items — "
    "let me know what you'd like to order or ask me for a recommendation!"
)


@router.post("", response_model=OrderResponse)
def create_order(payload: OrderRequest, db: Session = Depends(get_db)):
    # Step 1 — classify the message and extract item names / keywords
    extraction = ai_service.classify_message(payload.message)

    if extraction.message_type == "other":
        return OrderResponse(message_type="other", message=_OUT_OF_SCOPE_MESSAGE)

    if extraction.message_type == "order" and not extraction.items:
        raise HTTPException(status_code=422, detail="No items could be identified in the message.")

    # Step 2 — fuzzy-search the DB for candidates (pg_trgm)
    candidates = menu_service.search_by_names(db, payload.merchant_id, extraction.items)
    
    if extraction.message_type == "suggestion":
        if not candidates:
            return OrderResponse(message_type="suggestion", suggestions=[])

        # Step 3 — AI picks up to 10 recommended items from the candidates
        suggestions = ai_service.suggest_items(payload.message, candidates)
        return OrderResponse(
            message_type="suggestion",
            suggestions=[SuggestedItem(id=s.id, name=s.name, reason=s.reason) for s in suggestions],
        )

    # message_type == "order"
    if not candidates:
        return OrderResponse(message_type="order", unrecognized_items=extraction.items)
    
    # Step 3 — AI matches the original message against the ~20-30 candidates
    result = ai_service.parse_order(payload.message, candidates, extraction.items)

    order = None
    if result.matched_items:
        order = {
            "items": [
                {"id": item.id, "name": item.name, "qty": item.qty}
                for item in result.matched_items
            ]
        }

    ambiguous = (
        [
            AmbiguousItem(
                query=a.query,
                qty=a.qty,
                candidates=[{"id": c.id, "name": c.name} for c in a.candidates],
            )
            for a in result.ambiguous_items
        ]
        if result.ambiguous_items
        else None
    )

    return OrderResponse(
        message_type="order",
        order=order,
        ambiguous_items=ambiguous,
        unrecognized_items=result.unrecognized_items or None,
    )
