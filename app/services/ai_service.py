import json
import re
from typing import List

from openai import OpenAI

from app.core.config import settings
from app.models.zomato_item import ZomatoItem
from app.schemas.order import AIExtraction, AIOrderResult, AISuggestedItem

client = OpenAI(api_key=settings.OPENAI_API_KEY)


_LEADING_QTY_RE = re.compile(
    r"^(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten|a|an|few|couple(?:\s+of)?)\s+",
    re.IGNORECASE,
)


def _normalize_phrase(phrase: str) -> str:
    """Strip a leading quantity word/number so phrases like 'two apples' and
    'apples' compare equal."""
    return _LEADING_QTY_RE.sub("", phrase.strip().lower()).strip()


def _build_item_context(items: List[ZomatoItem]) -> List[dict]:
    return [
        {
            "id": item.id,
            "name": item.item_name,
            "description": " ".join(
                filter(None, [item.item_short_description, item.item_long_description])
            ),
        }
        for item in items
    ]


# ── Step 1: classify message & extract items/keywords ─────────────────────

_EXTRACT_SCHEMA = {
    "type": "object",
    "properties": {
        "message_type": {
            "type": "string",
            "enum": ["order", "suggestion", "other"],
            "description": "Classification of the customer's message.",
        },
        "items": {
            "type": "array",
            "description": (
                "For 'order': each distinct product/item name the customer wants, "
                "without quantities or modifiers. "
                "For 'suggestion': keywords describing what the customer is looking for "
                "(category, type, brand, material, color, size, use case, or other "
                "distinguishing attributes), "
                "or an empty array if the request is fully generic. "
                "For 'other': always an empty array."
            ),
            "items": {"type": "string"},
        },
    },
    "required": ["message_type", "items"],
    "additionalProperties": False,
}

_EXTRACT_SYSTEM_PROMPT = """Classify the customer's message and extract relevant search terms.

The customer may be ordering any kind of product — dishes, groceries, stationery, clothing, accessories, or anything else a store might sell.

message_type must be exactly one of:
- "order": the customer knows what they want and names specific products/items to order.
- "suggestion": the customer is undecided and is asking for recommendations, suggestions, or general questions about what's available (e.g. "what's good here?", "anything on offer?", "what do you recommend?").
- "other": the message is unrelated to ordering or getting product suggestions (greetings, complaints, small talk, unrelated questions).

items:
- If message_type is "order": list each distinct product/item name mentioned. Do not include quantities or modifiers (extra, without, large, red).
- If message_type is "suggestion": list keywords describing what the customer wants (category, type, brand, material, color, size, use case, or other distinguishing attributes). If the request is fully generic, return an empty array.
- If message_type is "other": always return an empty array.

Always respond with valid JSON matching the schema. No extra text."""


def classify_message(message: str) -> AIExtraction:
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=[
            {"role": "system", "content": _EXTRACT_SYSTEM_PROMPT},
            {"role": "user", "content": message},
        ],
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "classify_message",
                "strict": True,
                "schema": _EXTRACT_SCHEMA,
            },
        },
    )
    raw = response.choices[0].message.content
    
    return AIExtraction.model_validate(json.loads(raw))


# ── Step 3: match and structure the order ─────────────────────────────────

_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "matched_items": {
            "type": "array",
            "description": "Items that were unambiguously matched to a single catalog item.",
            "items": {
                "type": "object",
                "properties": {
                    "id":   {"type": "integer", "description": "item id"},
                    "name": {"type": "string"},
                    "qty":  {"type": "integer", "description": "quantity requested"},
                },
                "required": ["id", "name", "qty"],
                "additionalProperties": False,
            },
        },
        "ambiguous_items": {
            "type": "array",
            "description": "Items where the customer's request could match more than one catalog item.",
            "items": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "the phrase from the customer's message"},
                    "qty":   {"type": "integer"},
                    "candidates": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "id":   {"type": "integer"},
                                "name": {"type": "string"},
                            },
                            "required": ["id", "name"],
                            "additionalProperties": False,
                        },
                    },
                },
                "required": ["query", "qty", "candidates"],
                "additionalProperties": False,
            },
        },
        "unrecognized_items": {
            "type": "array",
            "description": "Phrases from the message that could not be matched to any catalog item.",
            "items": {"type": "string"},
        },
    },
    "required": ["matched_items", "ambiguous_items", "unrecognized_items"],
    "additionalProperties": False,
}

_SYSTEM_PROMPT = """You are an order-parsing assistant for a store that may sell any kind of product — dishes, groceries, stationery, clothing, accessories, or anything else.

You will receive:
1. A JSON array of available items, each with: id, name, description.
2. A customer's order message.

Your task:
- Identify every item and quantity the customer wants.
- For each requested item, find the best match(es) from the available items using the name and description.
- Each requested item must appear in EXACTLY ONE of matched_items, ambiguous_items, or unrecognized_items — never zero, never more than one.
- If there is exactly one clear match, add it to matched_items.
- If two or more items are plausible matches (e.g. "leather wallet" could be both "Brown Leather Wallet" and "Black Leather Wallet"), add it to ambiguous_items with ALL of those candidates (at least 2). Never add an item to ambiguous_items with fewer than 2 candidates.
- If zero items are a plausible match for a requested item, add the phrase to unrecognized_items. Do not also add it to ambiguous_items.
- When no quantity is explicitly stated, assume 1.
- Always respond with valid JSON matching the provided schema. No extra text."""


def parse_order(message: str, items: List[ZomatoItem]) -> AIOrderResult:
    item_context = _build_item_context(items)
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=[
            {"role": "system", "content": _SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"Available items:\n{json.dumps(item_context, ensure_ascii=False)}\n\n"
                    f"Customer order: {message}"
                ),
            },
        ],
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "order_result",
                "strict": True,
                "schema": _RESPONSE_SCHEMA,
            },
        },
    )

    raw = response.choices[0].message.content
    result = AIOrderResult.model_validate(json.loads(raw))

    # The model occasionally lists the same item in both ambiguous_items and
    # unrecognized_items, sometimes with a quantity word in one but not the
    # other (e.g. "masala dosa" vs "two masala dosa"). When it has already
    # proposed candidates, treat that as authoritative and drop the redundant
    # unrecognized_items entry.
    ambiguous_normalized = {_normalize_phrase(a.query) for a in result.ambiguous_items}
    result.unrecognized_items = [
        u for u in result.unrecognized_items if _normalize_phrase(u) not in ambiguous_normalized
    ]

    return result


# ── Step 3: recommend items for a "suggestion" message ─────────────────────

_SUGGEST_SCHEMA = {
    "type": "object",
    "properties": {
        "suggestions": {
            "type": "array",
            "description": "Up to 10 recommended items, ordered from most to least relevant.",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "integer", "description": "item id"},
                    "name": {"type": "string"},
                    "reason": {
                        "type": "string",
                        "description": "A short, friendly one-sentence reason for recommending this item.",
                    },
                },
                "required": ["id", "name", "reason"],
                "additionalProperties": False,
            },
        },
    },
    "required": ["suggestions"],
    "additionalProperties": False,
}

_SUGGEST_SYSTEM_PROMPT = """You are a friendly shopping assistant for a store that may sell any kind of product — dishes, groceries, stationery, clothing, accessories, or anything else.

You will receive:
1. A JSON array of available items, each with: id, name, description.
2. A customer's message asking for suggestions or recommendations.

Your task:
- Recommend up to 10 items from the provided list that best match what the customer is looking for, ordered from most to least relevant.
- Only recommend items that appear in the provided list — never invent items or ids.
- For each recommendation, give a short, friendly one-sentence reason.
- If fewer than 10 items are genuinely relevant, return fewer. Do not pad with irrelevant items.
- Always respond with valid JSON matching the provided schema. No extra text."""


def suggest_items(message: str, items: List[ZomatoItem]) -> List[AISuggestedItem]:
    item_context = _build_item_context(items)

    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=[
            {"role": "system", "content": _SUGGEST_SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"Available items:\n{json.dumps(item_context, ensure_ascii=False)}\n\n"
                    f"Customer message: {message}"
                ),
            },
        ],
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "suggestions_result",
                "strict": True,
                "schema": _SUGGEST_SCHEMA,
            },
        },
    )

    raw = response.choices[0].message.content
    return [AISuggestedItem.model_validate(s) for s in json.loads(raw)["suggestions"]]
