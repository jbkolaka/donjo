DROP INDEX IF EXISTS idx_push_devices_user;
DROP INDEX IF EXISTS idx_user_feeds_viewed;
DROP INDEX IF EXISTS idx_user_feeds_created;
DROP INDEX IF EXISTS idx_user_feeds_user;
DROP INDEX IF EXISTS idx_notifications_created;
DROP INDEX IF EXISTS idx_notifications_status;
DROP INDEX IF EXISTS idx_notifications_user;

DROP TABLE IF EXISTS push_devices;
DROP TABLE IF EXISTS notification_templates;
DROP TABLE IF EXISTS user_feeds;
DROP TABLE IF EXISTS notifications;