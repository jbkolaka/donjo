-- =============================================
-- ML SERVICE DATABASE (SQLite)
-- Ported from the Postgres/pgvector schema. Storage-aware substitutions:
--   * vector(128)   -> JSON array of floats stored as TEXT (cosine
--                      similarity computed in application code)
--   * UUID          -> TEXT, ids minted by the application as canonical
--                      hex UUIDs (same ids used across the microservices)
--   * JSONB         -> JSON (TEXT)
--   * TEXT[]        -> JSON array (TEXT)
--   * POINT / INET  -> TEXT
--   * DEFAULT uuid_generate_v4() / CURRENT_TIMESTAMP -> application-provided
--                      ids/timestamps; CURRENT_TIMESTAMP kept where a DB
--                      default is harmless
-- =============================================

-- USER EMBEDDINGS
CREATE TABLE IF NOT EXISTS user_embeddings (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,

    embedding_vector TEXT,
    category_weights TEXT,
    feature_vector TEXT,
    feature_version INTEGER DEFAULT 1,

    preferred_categories TEXT,
    preferred_venues TEXT,
    preferred_times TEXT,

    last_updated_at TEXT,
    last_calculated_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- EVENT EMBEDDINGS
CREATE TABLE IF NOT EXISTS event_embeddings (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL UNIQUE,

    embedding_vector TEXT,
    feature_vector TEXT,
    similar_events TEXT,
    feature_version INTEGER DEFAULT 1,

    last_calculated_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- USER INTERACTIONS
CREATE TABLE IF NOT EXISTS user_interactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    event_id TEXT,
    venue_id TEXT,

    interaction_type VARCHAR(50) NOT NULL,
    interaction_weight INTEGER DEFAULT 1,
    interaction_data TEXT,

    session_id TEXT,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INTEGER,
    position INTEGER,

    device_type TEXT,
    location TEXT,
    ip_address TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- RECOMMENDATIONS CACHE
CREATE TABLE IF NOT EXISTS recommendations_cache (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    results TEXT NOT NULL,
    model_version TEXT,
    request_context TEXT,
    expires_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, type)
);

-- AI QUERIES LOG
CREATE TABLE IF NOT EXISTS ai_queries (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    query_type TEXT NOT NULL,
    query_text TEXT,
    query_embedding TEXT,

    result_count INTEGER,
    results TEXT,
    selected_result TEXT,
    feedback INTEGER,

    response_time_ms INTEGER,
    tokens_used INTEGER,
    location TEXT,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_user_embeddings_user      ON user_embeddings(user_id);
CREATE INDEX IF NOT EXISTS idx_event_embeddings_event    ON event_embeddings(event_id);
CREATE INDEX IF NOT EXISTS idx_user_interactions_user    ON user_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_interactions_event   ON user_interactions(event_id);
CREATE INDEX IF NOT EXISTS idx_user_interactions_venue   ON user_interactions(venue_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_cache_user ON recommendations_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_queries_user           ON ai_queries(user_id);