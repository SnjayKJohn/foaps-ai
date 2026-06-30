# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Foaps AI is a standalone Python/FastAPI microservice that parses natural language product orders using OpenAI and returns structured order data. Items can be anything a merchant sells (dishes, groceries, stationery, clothing, accessories, etc.), not just food. It connects **read-only** to the existing Foaps PostgreSQL database (the same DB used by the main Ruby/Rails API) and runs alongside it as a separate service — there is no shared codebase with the Rails app.

The service exposes two feature tracks:
- **Single-shot order parsing** — `POST /api/v1/order`: classify a message and return matched/ambiguous/unrecognized items in one round-trip.
- **Conversational chat ordering** — `POST /api/v1/chat/start` + `POST /api/v1/chat/message`: stateful multi-turn flow where the AI asks clarifying questions, collects variant/group selections, and returns a finalized order JSON on confirmation.

## Commands

```bash
# Setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then fill in DATABASE_URL, OPENAI_API_KEY, OPENAI_MODEL

# Run the dev server
uvicorn app.main:app --reload
# API: http://localhost:8000, docs: http://localhost:8000/docs
```

There is currently no test suite or lint config in this repo.

One-time DB requirements:
- `pg_trgm` extension: `CREATE EXTENSION IF NOT EXISTS pg_trgm;` (fuzzy search)
- Chat tables migration: `psql $DATABASE_URL -f migrations/001_create_chat_tables.sql` (creates `ai_chat_sessions` and `ai_chat_messages`)

## Architecture

### Layering

`routers/` (FastAPI endpoints) → `services/` (business logic) → `models/` (SQLAlchemy ORM). Pydantic schemas for request/response validation live in `schemas/`. New endpoints are added as a new router module and registered in `app/main.py` via `app.include_router(...)`. CORS is enabled for all origins via `CORSMiddleware` in `app/main.py`.

**Rails tables** (read-only — never write to these):
- `app/models/zomato_item.py` — `ZomatoItem` mapped to `zomato_items` (see `schema.rb` for full schema)
- `app/models/zomato_customization.py` — `ZomatoItemVariant`, `ZomatoItemGroup`, `ZomatoItemGroupChoice` (read-only; map to `zomato_item_variants`, `zomato_item_groups`, `zomato_item_group_choices`)

**Service-owned tables** (writable, created by `migrations/001_create_chat_tables.sql`):
- `app/models/chat.py` — `AIChatSession`, `AIChatMessage`

**Services:**
- `app/core/config.py` — `pydantic-settings` config from `.env` (`DATABASE_URL`, `OPENAI_API_KEY`, `OPENAI_MODEL`)
- `app/core/database.py` — SQLAlchemy engine/session; `get_db()` FastAPI dependency
- `app/schemas/order.py` — single-shot order request/response + internal `AI*` models
- `app/schemas/chat.py` — chat request/response + `CartItem`, `ChosenGroup`
- `app/services/ai_service.py` — all OpenAI calls (see below)
- `app/services/menu_service.py` — DB queries against `zomato_items`; also `get_item_customizations()`
- `app/services/chat_service.py` — chat session CRUD and customer history lookup
- `app/routers/order.py` — `POST /api/v1/order`
- `app/routers/chat.py` — `POST /api/v1/chat/start`, `POST /api/v1/chat/message`

### Order parsing pipeline (3 steps)

The core flow in `order.py` exists because sending an entire catalog (potentially thousands of items) to OpenAI on every request is not viable. Instead:

1. **Extract** (`ai_service.classify_message`) — OpenAI classifies the message (`order`/`suggestion`/`other`) and extracts candidate item name strings or keywords from the raw customer message using a strict JSON-schema response.
2. **Search** (`menu_service.search_by_names`) — for each extracted name, fuzzy-search `zomato_items` via `pg_trgm` `similarity()` (threshold `0.15`) plus `ilike` fallback against `item_name`, `item_short_description`, `item_long_description`. Filters on `location_id`, `item_is_active == 1`, `item_in_stock == 1`. Results across all names are deduplicated by `id` (top ~10 per name).
3. **Match** (`ai_service.parse_order`) — only the narrowed candidate set (~20-30 items) plus the original message are sent to OpenAI, which returns `matched_items`, `ambiguous_items` (multiple plausible candidates for one phrase), and `unrecognized_items` (phrases with no catalog match), again via strict JSON-schema response format.

If step 2 returns zero candidates, the router short-circuits and returns all extracted names as `unrecognized_items` without a third OpenAI call.

### Chat ordering pipeline

The chat system (`routers/chat.py`) is a stateful multi-turn loop. Each session is stored in `ai_chat_sessions` (cart, pending clarifications, status) and its messages in `ai_chat_messages`.

**Session lifecycle:**

```
collecting ──(cart non-empty, nothing pending)──► confirming ──(confirmed)──► completed
                ◄─────────────────────────────────── modify ──────────────────┘
```

**`POST /api/v1/chat/start`**
- Request: `{ merchant_id, customer_phone? }`
- Creates a new `AIChatSession`, calls `generate_chat_reply()` with empty state to produce a greeting (includes previous order history in the prompt if `customer_phone` is given), saves the greeting message, returns `{ session_token, reply }`.

**`POST /api/v1/chat/message`**
- Request: `{ session_token, message }`
- Response: `{ reply, cart, status, finalized_order? }`

Per-turn logic (two paths run on every call):

1. **Path B — resolve pending** (runs first if `pending_clarifications` is non-empty):
   - *Ambiguity entries* (`type: "ambiguity"`): `resolve_clarification()` AI call identifies which candidate the user chose. Server validates the returned `chosen_id` against the stored candidate list. If the chosen item itself has variants/required groups, it becomes a customization entry; otherwise it goes straight into cart.
   - *Customization entries* (`type: "customization"`): `resolve_customization()` AI call maps the user's reply to specific variant ID and group choice IDs. Server validates all IDs. Resolved items are added to cart with full customization data.

2. **Path A — new item extraction** (always runs):
   - Same 3-step pipeline as `POST /api/v1/order` (classify → search → parse).
   - Matched items with variants or required groups → become customization pending entries.
   - Matched items without customizations → added to cart immediately.
   - Ambiguous items → become ambiguity pending entries.
   - Unrecognized items → passed to reply generator.

3. **Status transition:**
   - If status is `confirming`: call `detect_chat_intent()` → `confirmed/modify/cancel/unclear`.
   - If status is `collecting` and cart is non-empty and pending is empty → transition to `confirming`.

4. **Reply**: `generate_chat_reply()` produces a natural-language response appropriate for the current state.

5. **Persist**: user message + assistant reply saved to `ai_chat_messages`; session state updated atomically.

**`pending_clarifications` JSONB structure** (two entry types):

```json
// Ambiguity — which item did the customer mean?
{ "type": "ambiguity", "query": "chicken burger", "qty": 1,
  "candidates": [{ "id": 1, "name": "Crispy Chicken Burger" }, ...] }

// Customization — which variant/group choices for a confirmed item?
{ "type": "customization", "item_id": 123, "item_name": "Chicken Burger", "qty": 1,
  "merchant_id": 42,
  "variants": [{ "id": 10, "name": "Regular", "unit_price": 150 }, ...],
  "groups": [{ "id": 20, "name": "Sides", "min_selection": 1, "max_selection": 1,
               "choices": [{ "id": 5, "name": "French Fries", "price": 0 }, ...] }] }
```

**Cart item JSONB structure:**

```json
{ "id": 123, "name": "Chicken Burger", "qty": 1, "unit_price": 150.0,
  "variant_id": 11, "variant_name": "Large",
  "chosen_groups": [{ "group_id": 20, "group_name": "Sides",
                      "choice_id": 5, "choice_name": "French Fries", "price": 0.0 }] }
```

**Finalized order** (returned when `status == "completed"` and not cancelled):

```json
{ "session_token": "...", "merchant_id": 42, "customer_phone": "+91...",
  "items": [ <cart items with full variant/choice data> ] }
```

### AI functions in `ai_service.py`

| Function | Purpose | Output schema |
|---|---|---|
| `classify_message(message)` | Classify intent + extract item names | `AIExtraction` |
| `parse_order(message, items, phrases)` | Match phrases to catalog candidates | `AIOrderResult` |
| `suggest_items(message, items)` | Recommend items for suggestion requests | `List[AISuggestedItem]` |
| `resolve_clarification(message, pending, history)` | Pick which candidate resolves an ambiguous phrase | `{resolved, still_pending}` |
| `resolve_customization(message, pending, history)` | Map user reply to variant/choice IDs | `{resolved, still_pending_item_ids}` |
| `detect_chat_intent(message, history)` | Detect confirmed/modify/cancel/unclear | `str` |
| `generate_chat_reply(history, cart, pending, unrecognized, status, context)` | Produce natural-language reply | `str` |

All functions use `response_format={"type": "json_schema", "json_schema": {"strict": True, "schema": ...}}` — no free-text parsing.

### `zomato_items` table notes

`item_is_active` and `item_in_stock` are **integers** (default `1` = active/in stock), not booleans — always filter with `== 1`. Item text is split across `item_name`, `item_short_description`, and `item_long_description` (no single `description` column); `ai_service.parse_order` joins the two description fields together when building the OpenAI context.

### OpenAI integration conventions

All AI calls use `client.chat.completions.create` with `response_format={"type": "json_schema", "json_schema": {..., "strict": True, "schema": ...}}` and parse the result with `json.loads`. Follow this pattern (strict JSON schema, no free-text parsing) for any new AI-backed endpoints. Use `chosen_variant_id = 0` (not `null`) for "no variant selected" — OpenAI strict mode does not support nullable integer fields in all schema positions.

### `zomato_items` customization tables

Each menu item may have variants, choice groups, and addon groups linked by foreign key. The relevant read-only models are in `app/models/zomato_customization.py`. `menu_service.get_item_customizations(db, item_id)` loads all variants and groups (with choices) for a given item and returns `{ has_customizations, variants, groups }`. An item requires customization clarification if it has variants OR any group with `min_selection > 0`.

> **Addons** (`zomato_addon_groups`, `zomato_item_addons`): the base `zomato_addons` table is not yet mapped — addon support is a follow-up task.

### Test UI

`chat_test.html` — a self-contained browser UI for manual testing. Open the file directly in a browser. It accepts merchant ID, optional customer phone, and API base URL, then drives the full chat flow with a live cart and finalized order display.
