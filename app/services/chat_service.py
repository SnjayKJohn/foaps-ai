import secrets
from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.chat import AIChatMessage, AIChatSession


def create_session(
    db: Session, merchant_id: int, customer_phone: Optional[str]
) -> AIChatSession:
    session = AIChatSession(
        session_token=secrets.token_urlsafe(32),
        merchant_id=merchant_id,
        customer_phone=customer_phone,
        status="collecting",
        cart=[],
        pending_clarifications=[],
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def get_session(db: Session, session_token: str) -> Optional[AIChatSession]:
    return (
        db.query(AIChatSession)
        .filter(AIChatSession.session_token == session_token)
        .with_for_update()
        .first()
    )


def get_messages(db: Session, session_id: int, limit: int = 20) -> List[dict]:
    msgs = (
        db.query(AIChatMessage)
        .filter(AIChatMessage.session_id == session_id)
        .order_by(AIChatMessage.created_at)
        .all()
    )
    # Keep only the last `limit` messages to avoid exceeding the LLM context window
    msgs = msgs[-limit:]
    return [{"role": m.role, "content": m.content} for m in msgs]


def save_messages(db: Session, session_id: int, messages: List[dict]) -> None:
    for msg in messages:
        db.add(AIChatMessage(session_id=session_id, role=msg["role"], content=msg["content"]))
    db.commit()


def update_session_state(
    db: Session,
    session: AIChatSession,
    cart: List[dict],
    pending_clarifications: List[dict],
    status: str,
    finalized_order: Optional[dict] = None,
) -> None:
    # Always reassign whole columns to ensure SQLAlchemy detects JSONB changes
    session.cart = cart
    session.pending_clarifications = pending_clarifications
    session.status = status
    session.finalized_order = finalized_order
    db.commit()


def get_customer_context(db: Session, merchant_id: int, customer_phone: str) -> str:
    """Return a short summary of what the customer has previously ordered, or empty string."""
    if not customer_phone:
        return ""

    past_sessions = (
        db.query(AIChatSession)
        .filter(
            AIChatSession.merchant_id == merchant_id,
            AIChatSession.customer_phone == customer_phone,
            AIChatSession.status == "completed",
            AIChatSession.finalized_order.isnot(None),
        )
        .order_by(AIChatSession.created_at.desc())
        .limit(3)
        .all()
    )

    if not past_sessions:
        return ""

    seen: set = set()
    item_names: List[str] = []
    for s in past_sessions:
        for item in (s.finalized_order or {}).get("items", []):
            name = item.get("name")
            if name and name not in seen:
                seen.add(name)
                item_names.append(name)

    if not item_names:
        return ""

    return "Previously ordered: " + ", ".join(item_names[:10])
