from typing import List, Literal, Optional

from pydantic import BaseModel


# ── Nested structures stored in JSONB ──────────────────────────────────────

class ChosenGroup(BaseModel):
    group_id: int
    group_name: str
    choice_id: int
    choice_name: str
    price: float = 0.0


class CartItem(BaseModel):
    id: int
    name: str
    qty: int
    unit_price: float
    variant_id: Optional[int] = None
    variant_name: Optional[str] = None
    chosen_groups: List[ChosenGroup] = []


# ── API request schemas ─────────────────────────────────────────────────────

class ChatStartRequest(BaseModel):
    merchant_id: int
    customer_phone: Optional[str] = None


class ChatMessageRequest(BaseModel):
    session_token: str
    message: str


# ── API response schemas ────────────────────────────────────────────────────

class ChatStartResponse(BaseModel):
    session_token: str
    reply: str


class ChatSuggestedItem(BaseModel):
    id: int
    name: str
    reason: str


class ChatMessageResponse(BaseModel):
    reply: str
    cart: List[CartItem]
    status: Literal["collecting", "confirming", "completed"]
    finalized_order: Optional[dict] = None
    suggestions: Optional[List[ChatSuggestedItem]] = None
