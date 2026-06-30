import json
import re
from typing import List, Optional

from openai import OpenAI

from app.core.config import settings
from app.models.zomato_item import ZomatoItem
from app.schemas.order import (
    AIAmbiguousCandidate,
    AIAmbiguousItem,
    AIExtraction,
    AIOrderResult,
    AISuggestedItem,
)

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
- Identify every distinct item phrase and quantity the customer wants.
- Each distinct phrase from the customer's message must appear in EXACTLY ONE of matched_items, ambiguous_items, or unrecognized_items — never zero, never more than one.
- A single customer phrase maps to a SINGLE catalog item. Never add the same phrase to matched_items more than once, even if multiple catalog items look similar.
- If there is exactly one clear catalog match for the phrase, add it to matched_items.
- If two or more catalog items are all plausible matches for the same phrase (i.e. the customer's intent is unclear), add ONE entry to ambiguous_items listing ALL of those candidates. Never add an item to ambiguous_items with fewer than 2 candidates.
- If zero catalog items are a plausible match, add the phrase to unrecognized_items. Do not also add it to ambiguous_items.
- When no quantity is explicitly stated, assume 1.
- Always respond with valid JSON matching the provided schema. No extra text."""


def parse_order(message: str, items: List[ZomatoItem], extracted_phrases: Optional[List[str]] = None) -> AIOrderResult:
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

    # When the AI places multiple catalog items in matched_items for the same customer
    # phrase (e.g. "two Shawaya" → "Shawaya Mazbi Regular" qty=2 AND "Shawaya Mazbi
    # Masala" qty=2), detect it by checking whether an extracted phrase is a substring
    # of 2+ matched item names. If so, demote those items to ambiguous_items.
    if extracted_phrases and result.matched_items:
        ids_to_demote: set = set()
        for phrase in extracted_phrases:
            phrase_lower = _normalize_phrase(phrase)
            hits = [m for m in result.matched_items if phrase_lower in m.name.lower()]
            if len(hits) >= 2:
                ids_to_demote.update(m.id for m in hits)
                result.ambiguous_items.append(
                    AIAmbiguousItem(
                        query=phrase,
                        qty=hits[0].qty,
                        candidates=[AIAmbiguousCandidate(id=m.id, name=m.name) for m in hits],
                    )
                )
        if ids_to_demote:
            result.matched_items = [m for m in result.matched_items if m.id not in ids_to_demote]

    # If the model lists a candidate item in both ambiguous_items and matched_items,
    # ambiguous_items is authoritative — remove the duplicate from matched_items.
    ambiguous_candidate_ids = {c.id for a in result.ambiguous_items for c in a.candidates}
    result.matched_items = [
        m for m in result.matched_items if m.id not in ambiguous_candidate_ids
    ]

    # If the model lists the same query in both ambiguous_items and unrecognized_items
    # (sometimes with a leading quantity word difference), ambiguous_items is authoritative.
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


# ── Chat: resolve ambiguous item choice ───────────────────────────────────

_RESOLVE_AMBIGUITY_SCHEMA = {
    "type": "object",
    "properties": {
        "resolved": {
            "type": "array",
            "description": "Pending items that the customer's message now resolves.",
            "items": {
                "type": "object",
                "properties": {
                    "query":      {"type": "string", "description": "The original ambiguous phrase."},
                    "chosen_id":  {"type": "integer", "description": "ID of the candidate the customer chose."},
                    "qty":        {"type": "integer"},
                },
                "required": ["query", "chosen_id", "qty"],
                "additionalProperties": False,
            },
        },
        "still_pending": {
            "type": "array",
            "description": "Items still needing clarification because the customer's message didn't resolve them.",
            "items": {
                "type": "object",
                "properties": {
                    "query": {"type": "string"},
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
    },
    "required": ["resolved", "still_pending"],
    "additionalProperties": False,
}

_RESOLVE_AMBIGUITY_SYSTEM_PROMPT = """You are helping resolve an ordering clarification.

You will receive:
1. The conversation history (so you know which clarifying question was asked).
2. A list of pending ambiguous items, each with an original query and a list of candidates.
3. The customer's latest message.

Your task:
- Determine which pending items the customer's message resolves, and which candidate (by id) they chose.
- Only return chosen_id values that appear in the candidates list for that query.
- Items the message does not resolve remain in still_pending unchanged.
- Every pending item must appear in exactly one of resolved or still_pending.

Always respond with valid JSON matching the schema. No extra text."""


def resolve_clarification(
    user_message: str,
    ambiguity_pending: List[dict],
    history: List[dict],
) -> dict:
    messages = [{"role": "system", "content": _RESOLVE_AMBIGUITY_SYSTEM_PROMPT}]
    messages.extend(history)
    messages.append(
        {
            "role": "user",
            "content": (
                f"Pending clarifications:\n{json.dumps(ambiguity_pending, ensure_ascii=False)}\n\n"
                f"Customer's latest message: {user_message}"
            ),
        }
    )
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=messages,
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "resolve_clarification",
                "strict": True,
                "schema": _RESOLVE_AMBIGUITY_SCHEMA,
            },
        },
    )
    return json.loads(response.choices[0].message.content)


# ── Chat: resolve variant/group customization ─────────────────────────────

_RESOLVE_CUSTOMIZATION_SCHEMA = {
    "type": "object",
    "properties": {
        "resolved": {
            "type": "array",
            "description": "Items whose variant/group selections the customer has now provided.",
            "items": {
                "type": "object",
                "properties": {
                    "item_id": {"type": "integer"},
                    "chosen_variant_id": {
                        "type": "integer",
                        "description": "ID of the chosen variant. Use 0 if no variant applies or was not selected.",
                    },
                    "chosen_groups": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "group_id":   {"type": "integer"},
                                "choice_ids": {
                                    "type": "array",
                                    "items": {"type": "integer"},
                                },
                            },
                            "required": ["group_id", "choice_ids"],
                            "additionalProperties": False,
                        },
                    },
                },
                "required": ["item_id", "chosen_variant_id", "chosen_groups"],
                "additionalProperties": False,
            },
        },
        "still_pending_item_ids": {
            "type": "array",
            "description": "item_ids whose customization the customer has not yet answered.",
            "items": {"type": "integer"},
        },
    },
    "required": ["resolved", "still_pending_item_ids"],
    "additionalProperties": False,
}

_RESOLVE_CUSTOMIZATION_SYSTEM_PROMPT = """You are helping a customer customise their order items.

You will receive:
1. The conversation history (containing the customisation question you asked the customer).
2. A list of pending customisation items, each with optional variants and groups (with choices).
3. The customer's latest message.

Your task:
- Determine which items the customer has now customised, and capture their exact selections.
- For variants: return the id of the chosen variant, or 0 if the item has no variants / customer skipped.
- For groups: return the group_id and the list of choice_ids the customer selected.
- Only return ids that appear in the provided variants/choices lists.
- Items with required groups (min_selection > 0) that the customer hasn't addressed go to still_pending_item_ids.
- Items the customer fully addressed go to resolved.

Always respond with valid JSON matching the schema. No extra text."""


def resolve_customization(
    user_message: str,
    customization_pending: List[dict],
    history: List[dict],
) -> dict:
    messages = [{"role": "system", "content": _RESOLVE_CUSTOMIZATION_SYSTEM_PROMPT}]
    messages.extend(history)
    messages.append(
        {
            "role": "user",
            "content": (
                f"Pending customisations:\n{json.dumps(customization_pending, ensure_ascii=False)}\n\n"
                f"Customer's latest message: {user_message}"
            ),
        }
    )
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=messages,
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "resolve_customization",
                "strict": True,
                "schema": _RESOLVE_CUSTOMIZATION_SCHEMA,
            },
        },
    )
    return json.loads(response.choices[0].message.content)


# ── Chat: detect confirmation / modification intent ────────────────────────

_INTENT_SCHEMA = {
    "type": "object",
    "properties": {
        "intent": {
            "type": "string",
            "enum": ["confirmed", "modify", "cancel", "unclear"],
            "description": (
                "confirmed — customer approves the presented cart. "
                "modify — customer wants to change or add something. "
                "cancel — customer wants to cancel the order. "
                "unclear — the message does not clearly express any of the above."
            ),
        }
    },
    "required": ["intent"],
    "additionalProperties": False,
}

_INTENT_SYSTEM_PROMPT = """Classify the customer's intent in the context of a confirmation step.

The AI assistant just presented the customer's cart and asked them to confirm.
Classify the customer's reply as one of:
- "confirmed": they approve the order (yes, ok, sure, confirm, go ahead, looks good, etc.)
- "modify": they want to change or add something (no, wait, add, remove, actually, instead, etc.)
- "cancel": they want to cancel or don't want to order anymore
- "unclear": none of the above can be determined

Always respond with valid JSON matching the schema. No extra text."""


def detect_chat_intent(user_message: str, history: List[dict]) -> str:
    messages = [{"role": "system", "content": _INTENT_SYSTEM_PROMPT}]
    messages.extend(history)
    messages.append({"role": "user", "content": user_message})
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=messages,
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "detect_intent",
                "strict": True,
                "schema": _INTENT_SCHEMA,
            },
        },
    )
    return json.loads(response.choices[0].message.content)["intent"]


# ── Chat: generate a natural-language reply ───────────────────────────────

_REPLY_SCHEMA = {
    "type": "object",
    "properties": {
        "reply": {
            "type": "string",
            "description": "The assistant's reply to the customer. 1-4 sentences, friendly and concise.",
        }
    },
    "required": ["reply"],
    "additionalProperties": False,
}

_REPLY_SYSTEM_PROMPT_BASE = """You are a friendly ordering assistant for a restaurant or store.
Keep replies conversational and brief (1-4 sentences max).
Never invent items, prices, or IDs that weren't provided to you.

You will receive a JSON context block describing the current session state, then the conversation history, then the latest customer message.

Rules by status:
- "collecting": If pending_clarifications exist, handle them:
    - If a "cart_change" entry exists, ONLY ask the confirmation question — do NOT summarise or display the cart:
      - action "remove_item": ask "Just to confirm, should I remove <item_name> from your cart?"
      - action "cancel_order": ask "Are you sure you want to cancel your entire order? Your cart will be cleared."
    - If "ambiguity" type exists: ask the customer to choose between the listed candidates.
    - If "customization" type exists: ask the customer to select a variant or group choice.
  If unrecognized_items exist, mention you couldn't find them. Otherwise confirm what's been added to the cart so far and invite more items.
- "confirming": Present the full cart clearly and ask the customer to confirm. List each item with name, qty, variant (if any), and chosen groups (if any).
- "completed": Thank the customer warmly and let them know the order is confirmed.

If "just_cancelled" is true in the state block: the order was just cancelled. Warmly inform the customer their order has been cancelled and their cart is now empty. Invite them to start fresh with a new order whenever they're ready.

If "suggestions" is a non-empty list in the state block: present them as a numbered list in this format:
1. Item Name — reason
2. Item Name — reason
…
Then invite the customer to pick one or add any of them to their order.

If "out_of_scope" is true in the state block: the customer said something unrelated to ordering. Respond warmly, acknowledge their message briefly, then gently redirect them to placing an order or asking for suggestions. If there are pending clarifications or items in the cart, remind them so they don't lose their progress.

If the conversation history is empty, greet the customer and invite them to order.{context_line}"""


def generate_chat_reply(
    history: List[dict],
    cart: List[dict],
    pending_clarifications: List[dict],
    unrecognized: List[str],
    status: str,
    customer_context: str,
    out_of_scope: bool = False,
    suggestions: Optional[List[dict]] = None,
    just_cancelled: bool = False,
) -> str:
    context_line = f"\n\nNote: {customer_context}" if customer_context else ""
    system_prompt = _REPLY_SYSTEM_PROMPT_BASE.format(context_line=context_line)

    state_block = json.dumps(
        {
            "status": status,
            "cart": cart,
            "pending_clarifications": pending_clarifications,
            "unrecognized_items": unrecognized,
            "out_of_scope": out_of_scope,
            "suggestions": suggestions or [],
            "just_cancelled": just_cancelled,
        },
        ensure_ascii=False,
    )

    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(history)
    messages.append({"role": "user", "content": f"[session state]\n{state_block}"})

    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0.4,
        messages=messages,
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "chat_reply",
                "strict": True,
                "schema": _REPLY_SCHEMA,
            },
        },
    )
    return json.loads(response.choices[0].message.content)["reply"]


# ── Chat: detect cart modification intent ─────────────────────────────────

_CART_MOD_SCHEMA = {
    "type": "object",
    "properties": {
        "action": {
            "type": "string",
            "enum": ["remove_item", "update_qty", "cancel_order", "none"],
            "description": (
                "remove_item — customer wants to remove a specific item from the cart. "
                "update_qty — customer wants to change the quantity of a specific item. "
                "cancel_order — customer wants to cancel their entire order. "
                "none — message is not a cart modification request."
            ),
        },
        "item_id": {
            "type": "integer",
            "description": "Cart item id to act on. Use 0 if action is cancel_order or none.",
        },
        "item_name": {
            "type": "string",
            "description": "Name of the cart item. Use empty string if action is cancel_order or none.",
        },
        "new_qty": {
            "type": "integer",
            "description": "New quantity for update_qty action. Use 0 for all other actions.",
        },
    },
    "required": ["action", "item_id", "item_name", "new_qty"],
    "additionalProperties": False,
}

_CART_MOD_SYSTEM_PROMPT = """You are detecting whether a customer wants to modify their cart.

You will receive:
1. The current cart contents (JSON array of items with id, name, qty, etc.)
2. The conversation history.
3. The customer's latest message.

Determine if the customer is requesting one of:
- "remove_item": wants to remove a specific item from the cart
- "update_qty": wants to change the quantity of a specific item
- "cancel_order": wants to cancel their entire order / does not want to order anymore
- "none": the message is not a cart modification request

For remove_item and update_qty: identify the matching cart item by name. The item_id must be from the provided cart list; item_name should match the cart entry. For update_qty, set new_qty to the requested quantity. Use 0 for item_id and empty string for item_name when action is cancel_order or none.

Only return item_ids that appear in the provided cart. If the customer's reference doesn't match any cart item, return "none".

Always respond with valid JSON matching the schema. No extra text."""


def detect_cart_modification(
    user_message: str,
    cart: List[dict],
    history: List[dict],
) -> dict:
    messages = [{"role": "system", "content": _CART_MOD_SYSTEM_PROMPT}]
    messages.extend(history)
    messages.append(
        {
            "role": "user",
            "content": (
                f"Current cart:\n{json.dumps(cart, ensure_ascii=False)}\n\n"
                f"Customer's message: {user_message}"
            ),
        }
    )
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        temperature=0,
        messages=messages,
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "detect_cart_modification",
                "strict": True,
                "schema": _CART_MOD_SCHEMA,
            },
        },
    )
    return json.loads(response.choices[0].message.content)


# ── Step 3: recommend items for a "suggestion" message ─────────────────────

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
