DROP VIEW IF EXISTS event_with_venue;

DROP TRIGGER IF EXISTS update_tickets_updated_at;
DROP TRIGGER IF EXISTS update_venues_updated_at;
DROP TRIGGER IF EXISTS update_events_updated_at;

DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS venues;
DROP TABLE IF EXISTS events;
