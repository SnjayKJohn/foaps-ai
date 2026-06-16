# Foaps AI Service

A standalone Python microservice that parses natural language product orders using OpenAI and returns structured order data. Items can be anything a merchant sells — dishes, groceries, stationery, clothing, accessories, and more. It connects to the existing Foaps PostgreSQL database and is designed to run alongside the main Ruby API.

---

## How It Works

The client sends a natural language message and a `merchant_id`. The service first classifies the message, then processes it through a 3-step pipeline:

1. **Classify & extract** — OpenAI classifies the message as `order`, `suggestion`, or `other`, and extracts:
   - `order` → item names mentioned (e.g. `"chicken biryani"`, `"blue notebook"`)
   - `suggestion` → keywords describing what the customer wants (category, type, brand, material, color, size, etc.)
   - `other` → no items extracted
2. **Search** — The DB is fuzzy-searched using `pg_trgm` similarity on `item_name`, `item_short_description`, and `item_long_description`, returning up to 10 candidates per term (deduplicated)
3. **Respond**:
   - `order` → OpenAI receives the ~20–30 candidates and the original message, then returns matched items with quantities, ambiguous matches, and unrecognized items
   - `suggestion` → OpenAI receives the candidates and returns up to 10 recommended items, each with a short reason
   - `other` → a friendly message is returned immediately, explaining the request is out of scope — no DB search or further AI calls

This pipeline scales to catalogs with thousands of items — the DB does the heavy filtering, so OpenAI never processes the entire catalog. If a phrase could match multiple items, all candidates are returned for the client to resolve.

---

## Project Structure

```
foaps-ai/
├── app/
│   ├── main.py                  # FastAPI app entry point & router registration
│   ├── core/
│   │   ├── config.py            # Environment variable settings
│   │   └── database.py          # SQLAlchemy engine & session
│   ├── models/
│   │   └── zomato_item.py       # ZomatoItem ORM model
│   ├── schemas/
│   │   └── order.py             # Request/response Pydantic schemas
│   ├── services/
│   │   ├── menu_service.py      # pg_trgm fuzzy search for item candidates (Step 2)
│   │   └── ai_service.py        # Classification & extraction (Step 1), order parsing & suggestions (Step 3)
│   └── routers/
│       └── order.py             # POST /api/v1/order endpoint
├── .env.example
└── requirements.txt
```

---

## Setup

**1. Clone and create environment**
```bash
cd foaps-ai
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**2. Enable pg_trgm in PostgreSQL** (one-time, run in `psql` or a migration):
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

**3. Configure environment**
```bash
cp .env.example .env
```

Edit `.env` with your values:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/foaps_db
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
```

**4. Run the server**
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs`

---

## API Reference

### `POST /api/v1/order`

Parses a natural language message and returns one of three response shapes depending on `message_type`.

**Request**
```json
{
  "message": "I want one chicken biriyani and two masala dosa",
  "merchant_id": 5
}
```

#### `message_type: "order"`

**Response — all items matched**
```json
{
  "message_type": "order",
  "order": {
    "items": [
      { "id": 42, "qty": 1 },
      { "id": 15, "qty": 2 }
    ]
  }
}
```

**Response — ambiguous item**

When a phrase could match more than one item, the matched items are returned in `order` and the ambiguous ones are listed separately with all candidates.

```json
{
  "message_type": "order",
  "order": {
    "items": [
      { "id": 15, "qty": 2 }
    ]
  },
  "ambiguous_items": [
    {
      "query": "chicken biriyani",
      "qty": 1,
      "candidates": [
        { "id": 42, "name": "Chicken Biriyani" },
        { "id": 43, "name": "Chicken Dum Biriyani" }
      ]
    }
  ]
}
```

**Response — unrecognized item**

Items that couldn't be matched to anything in the catalog are listed under `unrecognized_items`.

```json
{
  "message_type": "order",
  "order": {
    "items": [{ "id": 42, "qty": 1 }]
  },
  "unrecognized_items": ["garlic bread"]
}
```

#### `message_type: "suggestion"`

For messages where the customer is asking for recommendations (e.g. `"what's good here?"`, `"any spicy starters?"`), up to 10 recommended items are returned with a short reason for each.

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
  "suggestions": [
    { "id": 11, "name": "Paneer Butter Masala", "reason": "A creamy, mildly spiced vegetarian classic." },
    { "id": 78, "name": "Tikka Masala", "reason": "A bold, spicy curry with rich flavor." }
  ]
}
```

If no items match the extracted keywords, `suggestions` is an empty array.

#### `message_type: "other"`

For messages unrelated to ordering or getting suggestions (greetings, complaints, unrelated questions), a friendly out-of-scope message is returned — no DB search or further AI calls are made.

**Response**
```json
{
  "message_type": "other",
  "message": "I can help you place an order or suggest items — let me know what you'd like to order or ask me for a recommendation!"
}
```

---

## Adding New Endpoints

1. Create a new file in [app/routers/](app/routers/)
2. Define a FastAPI `APIRouter`
3. Register it in [app/main.py](app/main.py) with `app.include_router(...)`

---

## Tech Stack

| Layer | Library |
|---|---|
| API framework | FastAPI |
| Database ORM | SQLAlchemy |
| Database driver | psycopg2 |
| Fuzzy search | pg_trgm (PostgreSQL extension) |
| AI / NLP | OpenAI (`gpt-4o-mini`) |
| Validation | Pydantic v2 |
| Config | pydantic-settings |


## TODOs 12.06
1. OpenAI API key
2. any other message_type
3. Business specific?
4. Prod DB clone
5. Deployment pipeline?
6. postgresql pg_trgm extension supported (trigram) - REQUIRED in prod


### Table
Table -> zomato_items ()