# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Foaps AI is a standalone Python/FastAPI microservice that parses natural language product orders using OpenAI and returns structured order data. Items can be anything a merchant sells (dishes, groceries, stationery, clothing, accessories, etc.), not just food. It connects **read-only** to the existing Foaps PostgreSQL database (the same DB used by the main Ruby/Rails API) and runs alongside it as a separate service — there is no shared codebase with the Rails app.

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

One-time DB requirement: the `pg_trgm` extension must be enabled (`CREATE EXTENSION IF NOT EXISTS pg_trgm;`) since fuzzy search depends on it.

## Architecture

### Layering

`routers/` (FastAPI endpoints) → `services/` (business logic) → `models/` (SQLAlchemy ORM, read-only mapping onto existing Rails tables). Pydantic schemas for request/response validation live in `schemas/`. New endpoints are added as a new router module and registered in `app/main.py` via `app.include_router(...)`.

- `app/core/config.py` — `pydantic-settings` config loaded from `.env` (`DATABASE_URL`, `OPENAI_API_KEY`, `OPENAI_MODEL`)
- `app/core/database.py` — SQLAlchemy engine/session; `get_db()` is the FastAPI dependency for DB access
- `app/models/zomato_item.py` — `ZomatoItem` ORM model mapped to the existing `zomato_items` table (see `schema.rb` for the full Rails schema/reference — this app only maps the columns it needs)
- `app/schemas/order.py` — request/response models, plus separate internal `AI*` models for the raw OpenAI structured-output shape
- `app/services/ai_service.py` — all OpenAI calls
- `app/services/menu_service.py` — DB queries against `zomato_items`
- `app/routers/order.py` — `POST /api/v1/order`

### Order parsing pipeline (3 steps)

The core flow in `order.py` exists because sending an entire catalog (potentially thousands of items) to OpenAI on every request is not viable. Instead:

1. **Extract** (`ai_service.classify_message`) — OpenAI classifies the message (`order`/`suggestion`/`other`) and extracts candidate item name strings or keywords from the raw customer message using a strict JSON-schema response.
2. **Search** (`menu_service.search_by_names`) — for each extracted name, fuzzy-search `zomato_items` via `pg_trgm` `similarity()` (threshold `0.15`) plus `ilike` fallback against `item_name`, `item_short_description`, `item_long_description`. Filters on `location_id`, `item_is_active == 1`, `item_in_stock == 1`. Results across all names are deduplicated by `id` (top ~10 per name).
3. **Match** (`ai_service.parse_order`) — only the narrowed candidate set (~20-30 items) plus the original message are sent to OpenAI, which returns `matched_items`, `ambiguous_items` (multiple plausible candidates for one phrase), and `unrecognized_items` (phrases with no catalog match), again via strict JSON-schema response format.

If step 2 returns zero candidates, the router short-circuits and returns all extracted names as `unrecognized_items` without a third OpenAI call.

### `zomato_items` table notes

`item_is_active` and `item_in_stock` are **integers** (default `1` = active/in stock), not booleans — always filter with `== 1`. Item text is split across `item_name`, `item_short_description`, and `item_long_description` (no single `description` column); `ai_service.parse_order` joins the two description fields together when building the OpenAI context.

### OpenAI integration conventions

Both AI calls use `client.chat.completions.create` with `response_format={"type": "json_schema", "json_schema": {..., "strict": True, "schema": ...}}` and parse the result with `json.loads` / `AIOrderResult.model_validate`. Follow this pattern (strict JSON schema, no free-text parsing) for any new AI-backed endpoints.
