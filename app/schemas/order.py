from typing import List, Literal, Optional

from pydantic import BaseModel


class OrderRequest(BaseModel):
    message: str
    merchant_id: int


# --- Internal AI response shapes ---

class AIExtraction(BaseModel):
    message_type: Literal["order", "suggestion", "other"]
    items: List[str]


class AIMatchedItem(BaseModel):
    id: int
    name: str
    qty: int


class AIAmbiguousCandidate(BaseModel):
    id: int
    name: str


class AIAmbiguousItem(BaseModel):
    query: str
    qty: int
    candidates: List[AIAmbiguousCandidate]


class AIOrderResult(BaseModel):
    matched_items: List[AIMatchedItem]
    ambiguous_items: List[AIAmbiguousItem]
    unrecognized_items: List[str]


class AISuggestedItem(BaseModel):
    id: int
    name: str
    reason: str


# --- API response shapes ---

class OrderItem(BaseModel):
    id: int
    name: str
    qty: int


class AmbiguousCandidate(BaseModel):
    id: int
    name: str


class AmbiguousItem(BaseModel):
    query: str
    qty: int
    candidates: List[AmbiguousCandidate]


class SuggestedItem(BaseModel):
    id: int
    name: str
    reason: str


class OrderResponse(BaseModel):
    message_type: Literal["order", "suggestion", "other"]
    order: Optional[dict] = None
    ambiguous_items: Optional[List[AmbiguousItem]] = None
    unrecognized_items: Optional[List[str]] = None
    suggestions: Optional[List[SuggestedItem]] = None
    message: Optional[str] = None
