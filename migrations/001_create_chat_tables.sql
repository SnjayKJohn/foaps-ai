-- Run this once against the Foaps Postgres DB before starting the chat service.
-- These are new tables managed exclusively by foaps-ai; no Rails models touch them.

CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id              BIGSERIAL PRIMARY KEY,
    session_token   TEXT UNIQUE NOT NULL,
    merchant_id     BIGINT NOT NULL,
    customer_phone  TEXT,
    status          TEXT NOT NULL DEFAULT 'collecting',   -- collecting | confirming | completed
    cart            JSONB NOT NULL DEFAULT '[]',          -- [{id, name, qty, unit_price, variant_id, variant_name, chosen_groups}]
    pending_clarifications JSONB NOT NULL DEFAULT '[]',  -- [{type, ...}]  see plan for structure
    finalized_order JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_token
    ON ai_chat_sessions (session_token);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_merchant_phone
    ON ai_chat_sessions (merchant_id, customer_phone);

CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id          BIGSERIAL PRIMARY KEY,
    session_id  BIGINT NOT NULL REFERENCES ai_chat_sessions(id),
    role        TEXT NOT NULL,     -- 'user' | 'assistant'
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_session
    ON ai_chat_messages (session_id);
