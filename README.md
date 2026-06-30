# Foaps AI Service

A standalone Python/FastAPI microservice that powers natural language ordering for Foaps merchants. Customers can type or speak their order in plain language — the service classifies the intent, searches the merchant's catalog using fuzzy matching, and uses OpenAI to resolve exactly what they want (including variants and customizations). It runs alongside the main Ruby/Rails API without sharing any code.

---

## Feature Overview

| Feature | Endpoint | Description |
|---|---|---|
| Single-shot order parsing | `POST /api/v1/order` | Classify a message, search the catalog, return matched/ambiguous/unrecognized items in one round-trip |
| Conversational chat ordering | `POST /api/v1/chat/start` + `POST /api/v1/chat/message` | Multi-turn AI chat that asks clarifying questions, collects variant and group-choice selections, and confirms the order |

---

## How It Works

### Single-shot pipeline (`/api/v1/order`)

Every request runs through three steps — the DB does the heavy filtering so OpenAI never sees the entire catalog:

1. **Classify & extract** (`ai_service.classify_message`) — OpenAI classifies the message as `order`, `suggestion`, or `other` and extracts search terms.
2. **Search** (`menu_service.search_by_names`) — Fuzzy-search `zomato_items` via `pg_trgm` `similarity()` (threshold 0.15) plus `ilike` fallback on `item_name`, `item_short_description`, `item_long_description`. Up to 10 results per term, deduplicated. Filters on `location_id`, `item_is_active = 1`, `item_in_stock = 1`.
3. **Respond** — For `order`: OpenAI receives ~20–30 candidates and the original message, returns matched items (with quantities), ambiguous items (multiple plausible candidates), and unrecognized items. For `suggestion`: OpenAI picks up to 10 recommended items with reasons, returned as a formatted indexed list. For `other`: a friendly out-of-scope message, no DB or AI calls.

### Conversational chat pipeline (`/api/v1/chat/*`)

A stateful multi-turn flow stored in Postgres. Each session holds a live cart and a list of pending clarifications (resolved turn by turn).

```
collecting ──(all items resolved)──► confirming ──(user confirms)──► completed
               ◄────────────────────── modify ──────────────────────────┘
```

**Per turn:**

- **Path B — resolve pending** (runs first): If there are items waiting for clarification, the AI resolves the user's reply against the pending list:
  - *Ambiguity*: user chose between multiple catalog matches for the same phrase
  - *Customization*: user selected a variant (size, spice level, etc.) or a required group choice (sides, sauces, etc.)
- **Path A — extract new items** (always runs): Same 3-step pipeline as the single-shot endpoint. Items with variants or required groups go into customization pending; others go straight into the cart.
- **Status transition**: If the cart is non-empty and nothing is pending → move to `confirming`. In `confirming`, the AI detects whether the user said yes, wants to modify, or wants to cancel.
- **Reply generation**: A final AI call generates a friendly, context-aware natural language reply for the current state.
- **Persist**: User message + assistant reply are saved to `ai_chat_messages`; cart and pending state are updated on `ai_chat_sessions`.

**Customer history**: If a `customer_phone` is provided, the last three completed sessions' item names are included in the AI prompt so returning customers get a personalised experience.

---

## Project Structure

```
foaps-ai/
├── app/
│   ├── main.py                        # FastAPI entry point, CORS, router registration
│   ├── core/
│   │   ├── config.py                  # pydantic-settings — DATABASE_URL, OPENAI_API_KEY, OPENAI_MODEL
│   │   └── database.py                # SQLAlchemy engine, SessionLocal, get_db() dependency
│   ├── models/
│   │   ├── zomato_item.py             # ZomatoItem (read-only, maps to zomato_items)
│   │   ├── zomato_customization.py    # ZomatoItemVariant, ZomatoItemGroup, ZomatoItemGroupChoice (read-only)
│   │   └── chat.py                    # AIChatSession, AIChatMessage (service-owned, writable)
│   ├── schemas/
│   │   ├── order.py                   # Single-shot request/response + internal AI* models
│   │   └── chat.py                    # Chat request/response, CartItem, ChosenGroup
│   ├── services/
│   │   ├── ai_service.py              # All OpenAI calls (7 functions — see AI Functions below)
│   │   ├── menu_service.py            # pg_trgm fuzzy search + get_item_customizations()
│   │   └── chat_service.py            # Session CRUD, message persistence, customer history
│   └── routers/
│       ├── order.py                   # POST /api/v1/order
│       └── chat.py                    # POST /api/v1/chat/start, POST /api/v1/chat/message
├── migrations/
│   └── 001_create_chat_tables.sql     # One-time migration for ai_chat_sessions + ai_chat_messages
├── chat_test.html                     # Self-contained browser test UI
├── schema.rb                          # Rails DB schema reference (read-only)
├── .env.example
└── requirements.txt
```

---

## Setup

**1. Clone and create environment**
```bash
cd foaps-ai
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**2. Configure environment**
```bash
cp .env.example .env
```
Edit `.env`:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/foaps_db
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
```

**3. One-time database setup**
```bash
# Enable fuzzy search extension
psql $DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Create chat session tables
psql $DATABASE_URL -f migrations/001_create_chat_tables.sql
```

**4. Run the server**
```bash
uvicorn app.main:app --reload
# API:  http://localhost:8000
# Docs: http://localhost:8000/docs
```

**5. Test with the browser UI**

Open `chat_test.html` directly in your browser (no server needed). Enter your merchant ID, optionally a customer phone number, and start chatting.

---

## API Reference

### `POST /api/v1/order`

Single-shot order parsing. Returns one response shape depending on `message_type`.

**Request**
```json
{
  "message": "I want one chicken biryani and two masala dosa",
  "merchant_id": 5
}
```

#### Response — `message_type: "order"` (all matched)
```json
{
  "message_type": "order",
  "order": {
    "items": [
      { "id": 42, "name": "Chicken Biryani", "qty": 1 },
      { "id": 15, "name": "Masala Dosa",     "qty": 2 }
    ]
  }
}
```

#### Response — `message_type: "order"` (ambiguous item)
When a phrase matches more than one catalog item, those items are returned in `ambiguous_items` with all candidates for the client to resolve.

```json
{
  "message_type": "order",
  "order": {
    "items": [{ "id": 15, "name": "Masala Dosa", "qty": 2 }]
  },
  "ambiguous_items": [
    {
      "query": "chicken biryani",
      "qty": 1,
      "candidates": [
        { "id": 42, "name": "Chicken Biryani" },
        { "id": 43, "name": "Chicken Dum Biryani" }
      ]
    }
  ]
}
```

#### Response — `message_type: "order"` (unrecognized item)
```json
{
  "message_type": "order",
  "order": { "items": [{ "id": 42, "name": "Chicken Biryani", "qty": 1 }] },
  "unrecognized_items": ["garlic bread"]
}
```

#### Response — `message_type: "suggestion"`
For messages like `"what's good here?"` or `"any spicy vegetarian options?"`. Returns up to 10 recommended items with reasons, plus a formatted indexed list in `message` ready to display.

**Request**
```json
{
  "message": "Can you suggest something spicy and vegetarian?",
  "merchant_id": 5
}
```
**Response**
```json
{
  "message_type": "suggestion",
  "message": "Here are some suggestions for you:\n\n1. Paneer Tikka — A smoky, spiced vegetarian starter perfect for spice lovers\n2. Veg Kolhapuri — A fiery mixed vegetable curry with bold flavours",
  "suggestions": [
    { "id": 11, "name": "Paneer Tikka",    "reason": "A smoky, spiced vegetarian starter perfect for spice lovers" },
    { "id": 78, "name": "Veg Kolhapuri",   "reason": "A fiery mixed vegetable curry with bold flavours" }
  ]
}
```

#### Response — `message_type: "other"`
Out-of-scope messages (greetings, complaints, unrelated questions). No DB search or extra AI calls.
```json
{
  "message_type": "other",
  "message": "I can help you place an order or suggest items — let me know what you'd like to order or ask me for a recommendation!"
}
```

---

### `POST /api/v1/chat/start`

Creates a new chat session and returns a greeting.

**Request**
```json
{
  "merchant_id": 5,
  "customer_phone": "+919876543210"
}
```
`customer_phone` is optional. When provided, the last three completed sessions for that customer are used to personalise the greeting.

**Response**
```json
{
  "session_token": "abc123...",
  "reply": "Welcome back! Last time you ordered Butter Chicken and Garlic Naan. What would you like today?"
}
```

---

### `POST /api/v1/chat/message`

Send a message in an existing session. The server runs the full per-turn pipeline and returns an updated cart and reply.

**Request**
```json
{
  "session_token": "abc123...",
  "message": "I want a chicken burger and a coke"
}
```

**Response — clarification needed (item ambiguous)**
```json
{
  "reply": "I found a few chicken burgers on the menu. Which one would you like?\n1. Crispy Chicken Burger\n2. Spicy Chicken Burger",
  "cart": [],
  "status": "collecting",
  "finalized_order": null
}
```

**Response — customization needed (item has variants)**
```json
{
  "reply": "Got it! For the Shawaya, which variant would you like — Half or Full?",
  "cart": [
    { "id": 88, "name": "Coca-Cola", "qty": 1, "unit_price": 60.0, "variant_id": null, "variant_name": null, "chosen_groups": [] }
  ],
  "status": "collecting",
  "finalized_order": null
}
```

**Response — confirming (all items resolved)**
```json
{
  "reply": "Here's your order:\n- Spicy Chicken Burger × 1\n- Coca-Cola × 1\n\nShall I confirm this?",
  "cart": [
    { "id": 55, "name": "Spicy Chicken Burger", "qty": 1, "unit_price": 180.0, "variant_id": null, "variant_name": null, "chosen_groups": [] },
    { "id": 88, "name": "Coca-Cola",            "qty": 1, "unit_price": 60.0,  "variant_id": null, "variant_name": null, "chosen_groups": [] }
  ],
  "status": "confirming",
  "finalized_order": null
}
```

**Response — completed (user confirmed)**
```json
{
  "reply": "Your order is confirmed! Thank you. 🎉",
  "cart": [ ... ],
  "status": "completed",
  "finalized_order": {
    "session_token": "abc123...",
    "merchant_id": 5,
    "customer_phone": "+919876543210",
    "items": [
      {
        "id": 55, "name": "Spicy Chicken Burger", "qty": 1, "unit_price": 180.0,
        "variant_id": null, "variant_name": null, "chosen_groups": []
      },
      {
        "id": 88, "name": "Coca-Cola", "qty": 1, "unit_price": 60.0,
        "variant_id": null, "variant_name": null, "chosen_groups": []
      }
    ]
  }
}
```

**Cart item with variant and group choice**
```json
{
  "id": 12,
  "name": "Shawaya Mazbi",
  "qty": 2,
  "unit_price": 350.0,
  "variant_id": 3,
  "variant_name": "Full",
  "chosen_groups": [
    { "group_id": 20, "group_name": "Sides", "choice_id": 5, "choice_name": "French Fries", "price": 0.0 }
  ]
}
```

#### Session status values

| Status | Meaning |
|---|---|
| `collecting` | Gathering items; may have pending clarifications or customizations |
| `confirming` | Cart is complete; AI is asking the customer to confirm |
| `completed` | Order confirmed (or cancelled). `finalized_order` is set. Further messages return HTTP 400 |

---

## AI Functions

All OpenAI calls use `response_format` strict JSON schema — no free-text parsing anywhere.

| Function | When called | Returns |
|---|---|---|
| `classify_message(message)` | Every `/order` and `/chat/message` request | Intent type + extracted item names/keywords |
| `parse_order(message, candidates, phrases)` | After fuzzy search finds candidates | Matched, ambiguous, and unrecognized items |
| `suggest_items(message, candidates)` | `suggestion` intent with candidates | Up to 10 items with reasons |
| `resolve_clarification(message, pending, history)` | Pending ambiguity entries exist | Which candidate the user chose per query |
| `resolve_customization(message, pending, history)` | Pending customization entries exist | Chosen variant ID + group choice IDs per item |
| `detect_chat_intent(message, history)` | Session is in `confirming` state | `confirmed` / `modify` / `cancel` / `unclear` |
| `generate_chat_reply(history, cart, pending, unrecognized, status, context)` | Every `/chat/message` request | Natural language reply string |

---

## Database

### Rails tables (read-only)

This service never writes to Rails-managed tables.

| Table | Used for |
|---|---|
| `zomato_items` | Menu item catalog — fuzzy-searched for candidates |
| `zomato_item_variants` | Variants per item (size, spice level, etc.) |
| `zomato_item_groups` | Choice groups per item (sides, sauces, etc.) |
| `zomato_item_group_choices` | Individual choices within a group |

### Service-owned tables (writable)

Created by `migrations/001_create_chat_tables.sql`.

**`ai_chat_sessions`**

| Column | Type | Description |
|---|---|---|
| `session_token` | text | Unique token returned to the client |
| `merchant_id` | bigint | The location/merchant this session belongs to |
| `customer_phone` | text | Optional; used for cross-session history |
| `status` | text | `collecting` / `confirming` / `completed` |
| `cart` | jsonb | Array of resolved cart items with variant/choice data |
| `pending_clarifications` | jsonb | Array of unresolved ambiguity or customization entries |
| `finalized_order` | jsonb | Set when status = `completed` |

**`ai_chat_messages`**

| Column | Type | Description |
|---|---|---|
| `session_id` | bigint | FK to `ai_chat_sessions` |
| `role` | text | `user` or `assistant` |
| `content` | text | Message text |

---

## Tech Stack

| Layer | Library |
|---|---|
| API framework | FastAPI |
| Database ORM | SQLAlchemy |
| Database driver | psycopg2 |
| Fuzzy search | pg_trgm (PostgreSQL extension) |
| AI / NLP | OpenAI (default: `gpt-4o-mini`) |
| Validation | Pydantic v2 |
| Config | pydantic-settings |

---

## Adding New Endpoints

1. Create `app/routers/your_feature.py` with a FastAPI `APIRouter`
2. Add any new ORM models to `app/models/`
3. Add Pydantic schemas to `app/schemas/`
4. Add business logic to `app/services/`
5. Register the router in `app/main.py`: `app.include_router(your_router, prefix="/api/v1")`
6. If new AI calls are needed, follow the strict JSON schema pattern in `ai_service.py`
