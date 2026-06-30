from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.zomato_item import ZomatoItem
from app.schemas.chat import (
    CartItem,
    ChosenGroup,
    ChatMessageRequest,
    ChatMessageResponse,
    ChatStartRequest,
    ChatStartResponse,
    ChatSuggestedItem,
)
from app.services import ai_service, chat_service, menu_service

router = APIRouter(prefix="/chat", tags=["chat"])


# ── helpers ────────────────────────────────────────────────────────────────

def _merge_cart(cart: List[dict]) -> List[dict]:
    """Merge duplicate cart entries by (id, variant_id), accumulating qty."""
    merged: dict = {}
    for item in cart:
        key = (item["id"], item.get("variant_id"))
        if key in merged:
            merged[key]["qty"] += item["qty"]
        else:
            merged[key] = dict(item)
    return list(merged.values())


def _apply_resolved_customization(
    db: Session,
    resolved: dict,
    customization_entry: dict,
) -> dict:
    """
    Build a cart item dict from a resolved customization AI response
    and the original pending customization entry.
    """
    item_id = resolved["item_id"]
    chosen_variant_id = resolved.get("chosen_variant_id", 0) or 0

    # Build a lookup of valid variants and choices from the pending entry
    variant_map = {v["id"]: v for v in customization_entry.get("variants", [])}
    group_map = {g["id"]: g for g in customization_entry.get("groups", [])}

    # Resolve variant
    variant_id = None
    variant_name = None
    unit_price = 0.0

    if chosen_variant_id and chosen_variant_id in variant_map:
        v = variant_map[chosen_variant_id]
        variant_id = v["id"]
        variant_name = v["name"]
        unit_price = float(v.get("unit_price") or 0)
    else:
        # Fall back to item's base price from DB
        item_record = (
            db.query(ZomatoItem)
            .filter(
                ZomatoItem.id == item_id,
                ZomatoItem.location_id == customization_entry.get("merchant_id"),
            )
            .first()
        )
        if item_record:
            unit_price = float(item_record.item_final_price or 0)

    # Resolve group choices
    chosen_groups: List[dict] = []
    for group_choice in resolved.get("chosen_groups", []):
        group_id = group_choice["group_id"]
        if group_id not in group_map:
            continue
        group = group_map[group_id]
        choice_map = {c["id"]: c for c in group.get("choices", [])}
        for choice_id in group_choice.get("choice_ids", []):
            if choice_id not in choice_map:
                continue
            c = choice_map[choice_id]
            chosen_groups.append(
                {
                    "group_id": group_id,
                    "group_name": group.get("name", ""),
                    "choice_id": choice_id,
                    "choice_name": c.get("name", ""),
                    "price": float(c.get("price") or 0),
                }
            )

    return {
        "id": item_id,
        "name": customization_entry["item_name"],
        "qty": customization_entry["qty"],
        "unit_price": unit_price,
        "variant_id": variant_id,
        "variant_name": variant_name,
        "chosen_groups": chosen_groups,
    }


# ── POST /chat/start ───────────────────────────────────────────────────────

@router.post("/start", response_model=ChatStartResponse)
def start_chat(payload: ChatStartRequest, db: Session = Depends(get_db)):
    session = chat_service.create_session(db, payload.merchant_id, payload.customer_phone)

    customer_context = ""
    if payload.customer_phone:
        customer_context = chat_service.get_customer_context(
            db, payload.merchant_id, payload.customer_phone
        )

    reply = ai_service.generate_chat_reply(
        history=[],
        cart=[],
        pending_clarifications=[],
        unrecognized=[],
        status="collecting",
        customer_context=customer_context,
    )

    chat_service.save_messages(db, session.id, [{"role": "assistant", "content": reply}])

    return ChatStartResponse(session_token=session.session_token, reply=reply)


# ── POST /chat/message ─────────────────────────────────────────────────────

@router.post("/message", response_model=ChatMessageResponse)
def send_message(payload: ChatMessageRequest, db: Session = Depends(get_db)):
    # ── load state ──────────────────────────────────────────────────────────
    session = chat_service.get_session(db, payload.session_token)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    if session.status == "completed":
        raise HTTPException(status_code=400, detail="This session is already completed.")

    history = chat_service.get_messages(db, session.id)
    cart: List[dict] = list(session.cart or [])
    pending: List[dict] = list(session.pending_clarifications or [])
    status = session.status
    finalized_order = session.finalized_order
    unrecognized: List[str] = []
    just_cancelled = False

    # ── Path B: resolve pending clarifications ─────────────────────────────
    ambiguity_pending = [p for p in pending if p.get("type") == "ambiguity"]
    customization_pending = [p for p in pending if p.get("type") == "customization"]
    cart_change_pending = [p for p in pending if p.get("type") == "cart_change"]

    # B3: resolve cart modification confirmation (remove / update qty / cancel order)
    if cart_change_pending:
        entry = cart_change_pending[0]
        confirmation = ai_service.detect_chat_intent(payload.message, history)
        if confirmation == "confirmed":
            action = entry.get("action")
            if action == "remove_item":
                cart = [item for item in cart if item["id"] != entry["item_id"]]
            elif action == "update_qty":
                for item in cart:
                    if item["id"] == entry["item_id"]:
                        item["qty"] = entry["new_qty"]
            elif action == "cancel_order":
                cart = []
                just_cancelled = True
            cart_change_pending = []
            status = "collecting"  # re-evaluate after the change
        elif confirmation in ("modify", "cancel"):
            # user said no — drop the pending action
            cart_change_pending = []
            status = "collecting"
        # "unclear" → keep pending, status unchanged

    # B1: resolve item ambiguities
    if ambiguity_pending:
        result = ai_service.resolve_clarification(payload.message, ambiguity_pending, history)

        for resolved_item in result.get("resolved", []):
            query = resolved_item["query"]
            chosen_id = resolved_item["chosen_id"]
            qty = resolved_item["qty"]

            # validate chosen_id against the candidates list
            entry = next((p for p in ambiguity_pending if p["query"] == query), None)
            if entry is None:
                continue
            valid_ids = {c["id"] for c in entry.get("candidates", [])}
            if chosen_id not in valid_ids:
                continue  # hallucinated id — keep it pending

            # check if chosen item itself has required customizations
            customizations = menu_service.get_item_customizations(db, chosen_id)
            if customizations["has_customizations"]:
                customization_pending.append(
                    {
                        "type": "customization",
                        "item_id": chosen_id,
                        "item_name": next(
                            (c["name"] for c in entry["candidates"] if c["id"] == chosen_id),
                            str(chosen_id),
                        ),
                        "qty": qty,
                        "merchant_id": session.merchant_id,
                        "variants": customizations["variants"],
                        "groups": customizations["groups"],
                    }
                )
            else:
                item_record = (
                    db.query(ZomatoItem)
                    .filter(
                        ZomatoItem.id == chosen_id,
                        ZomatoItem.location_id == session.merchant_id,
                    )
                    .first()
                )
                cart.append(
                    {
                        "id": chosen_id,
                        "name": next(
                            (c["name"] for c in entry["candidates"] if c["id"] == chosen_id),
                            str(chosen_id),
                        ),
                        "qty": qty,
                        "unit_price": float(item_record.item_final_price or 0) if item_record else 0.0,
                        "variant_id": None,
                        "variant_name": None,
                        "chosen_groups": [],
                    }
                )

        ambiguity_pending = result.get("still_pending", [])
        # restore type field (resolve_clarification doesn't include it in its schema output)
        for p in ambiguity_pending:
            p.setdefault("type", "ambiguity")

    # B2: resolve customizations (variant / group choices)
    if customization_pending:
        result = ai_service.resolve_customization(payload.message, customization_pending, history)

        still_pending_ids = set(result.get("still_pending_item_ids", []))
        resolved_ids = {r["item_id"] for r in result.get("resolved", [])}

        for resolved in result.get("resolved", []):
            entry = next(
                (p for p in customization_pending if p["item_id"] == resolved["item_id"]), None
            )
            if entry is None:
                continue
            cart.append(_apply_resolved_customization(db, resolved, entry))

        # keep entries that weren't resolved
        customization_pending = [
            p
            for p in customization_pending
            if p["item_id"] in still_pending_ids or p["item_id"] not in resolved_ids
        ]

    # rebuild pending list
    pending = ambiguity_pending + customization_pending + cart_change_pending

    # ── Path A: classify and process new items ─────────────────────────────
    extraction = ai_service.classify_message(payload.message)
    out_of_scope = extraction.message_type == "other"
    chat_suggestions: List[dict] = []

    if extraction.message_type == "suggestion":
        candidates = menu_service.search_by_names(db, session.merchant_id, extraction.items)
        if candidates:
            raw = ai_service.suggest_items(payload.message, candidates)
            chat_suggestions = [{"id": s.id, "name": s.name, "reason": s.reason} for s in raw]

    if extraction.message_type == "order" and extraction.items:
        candidates = menu_service.search_by_names(db, session.merchant_id, extraction.items)

        if candidates:
            order_result = ai_service.parse_order(
                payload.message, candidates, extraction.items
            )
            unrecognized = order_result.unrecognized_items or []

            # candidate lookup for unit_price
            candidate_map = {c.id: c for c in candidates}

            for matched in order_result.matched_items:
                customizations = menu_service.get_item_customizations(db, matched.id)
                if customizations["has_customizations"]:
                    pending.append(
                        {
                            "type": "customization",
                            "item_id": matched.id,
                            "item_name": matched.name,
                            "qty": matched.qty,
                            "merchant_id": session.merchant_id,
                            "variants": customizations["variants"],
                            "groups": customizations["groups"],
                        }
                    )
                else:
                    item_record = candidate_map.get(matched.id)
                    cart.append(
                        {
                            "id": matched.id,
                            "name": matched.name,
                            "qty": matched.qty,
                            "unit_price": float(
                                item_record.item_final_price or 0
                            ) if item_record else 0.0,
                            "variant_id": None,
                            "variant_name": None,
                            "chosen_groups": [],
                        }
                    )

            for ambig in order_result.ambiguous_items:
                pending.append(
                    {
                        "type": "ambiguity",
                        "query": ambig.query,
                        "qty": ambig.qty,
                        "candidates": [
                            {"id": c.id, "name": c.name} for c in ambig.candidates
                        ],
                    }
                )
        else:
            unrecognized = extraction.items

    # ── Cart modification detection ─────────────────────────────────────────
    # When the message isn't an order/suggestion, the cart has items, and there's
    # no cart change already awaiting confirmation — check for remove/update/cancel.
    if extraction.message_type == "other" and cart and not cart_change_pending:
        mod = ai_service.detect_cart_modification(payload.message, cart, history)
        if mod["action"] != "none":
            out_of_scope = False
            if mod["action"] == "update_qty":
                # Apply quantity update directly — no confirmation needed
                for item in cart:
                    if item["id"] == mod["item_id"]:
                        item["qty"] = mod["new_qty"]
            else:
                # remove_item and cancel_order are destructive — require confirmation
                cart_change_pending.append(
                    {
                        "type": "cart_change",
                        "action": mod["action"],
                        "item_id": mod["item_id"],
                        "item_name": mod["item_name"],
                        "new_qty": mod["new_qty"],
                    }
                )
                pending = ambiguity_pending + customization_pending + cart_change_pending

    # ── Deduplication ──────────────────────────────────────────────────────
    cart = _merge_cart(cart)

    # ── Status transitions ─────────────────────────────────────────────────
    if status == "confirming":
        intent = ai_service.detect_chat_intent(payload.message, history)
        if intent == "confirmed":
            status = "completed"
            finalized_order = {
                "session_token": session.session_token,
                "merchant_id": session.merchant_id,
                "customer_phone": session.customer_phone,
                "items": cart,
            }
        elif intent == "modify":
            status = "collecting"
        elif intent == "cancel":
            # Ask for confirmation before cancelling — don't immediately clear
            if not any(p.get("action") == "cancel_order" for p in cart_change_pending):
                cart_change_pending.append(
                    {
                        "type": "cart_change",
                        "action": "cancel_order",
                        "item_id": 0,
                        "item_name": "",
                        "new_qty": 0,
                    }
                )
                pending = ambiguity_pending + customization_pending + cart_change_pending
            status = "collecting"
        # "unclear" → stay in confirming

    if status == "collecting":
        if cart and not pending:
            status = "confirming"

    # ── Generate reply ─────────────────────────────────────────────────────
    customer_context = ""
    if session.customer_phone:
        customer_context = chat_service.get_customer_context(
            db, session.merchant_id, session.customer_phone
        )

    reply = ai_service.generate_chat_reply(
        history=history,
        cart=cart,
        pending_clarifications=pending,
        unrecognized=unrecognized,
        status=status,
        customer_context=customer_context,
        out_of_scope=out_of_scope,
        suggestions=chat_suggestions,
        just_cancelled=just_cancelled,
    )

    # ── Persist ────────────────────────────────────────────────────────────
    chat_service.save_messages(
        db,
        session.id,
        [
            {"role": "user", "content": payload.message},
            {"role": "assistant", "content": reply},
        ],
    )
    chat_service.update_session_state(db, session, cart, pending, status, finalized_order)

    return ChatMessageResponse(
        reply=reply,
        cart=[CartItem(**item) for item in cart],
        status=status,
        finalized_order=finalized_order if status == "completed" else None,
        suggestions=[ChatSuggestedItem(**s) for s in chat_suggestions] or None,
    )
