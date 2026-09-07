-- =============================================
-- ML SERVICE RUNTIME ENRICHMENT
-- Columns/tables the service fills while running:
--  * denormalised event payload so recommendation responses can render a
--    catalog item without calling donjo_event
--  * popularity + published flag + queryable start/end/city/category
--  * interaction_count on user profiles
--  * venue_docs so events can be feature-augmented by their venue
-- =============================================

ALTER TABLE event_embeddings ADD COLUMN payload_json TEXT;
ALTER TABLE event_embeddings ADD COLUMN popularity REAL DEFAULT 0;
ALTER TABLE event_embeddings ADD COLUMN is_published INTEGER DEFAULT 0;
ALTER TABLE event_embeddings ADD COLUMN status TEXT DEFAULT 'draft';
ALTER TABLE event_embeddings ADD COLUMN start_time TEXT;
ALTER TABLE event_embeddings ADD COLUMN end_time TEXT;
ALTER TABLE event_embeddings ADD COLUMN city TEXT;
ALTER TABLE event_embeddings ADD COLUMN category TEXT;

ALTER TABLE user_embeddings ADD COLUMN interaction_count INTEGER DEFAULT 0;

CREATE TABLE IF NOT EXISTS venue_docs (
    venue_id TEXT PRIMARY KEY,
    name TEXT,
    slug TEXT,
    venue_type TEXT,
    venue_category TEXT,
    address TEXT,
    city TEXT,
    county TEXT,
    country TEXT,
    capacity INTEGER,
    status TEXT DEFAULT 'active',
    payload_json TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_venue_docs_city ON venue_docs(city);