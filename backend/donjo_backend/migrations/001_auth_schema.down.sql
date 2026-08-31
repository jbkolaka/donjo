-- =============================================
-- ROLLBACK: Drop all authentication tables
-- =============================================

DROP TRIGGER IF EXISTS update_users_updated_at;
DROP TRIGGER IF EXISTS update_refresh_tokens_updated_at;
DROP TRIGGER IF EXISTS update_user_preferences_updated_at;

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS rate_limits;
DROP TABLE IF EXISTS token_blocklist;
DROP TABLE IF EXISTS social_accounts;
DROP TABLE IF EXISTS user_activity_log;
DROP TABLE IF EXISTS login_history;
DROP TABLE IF EXISTS two_factor_auth;
DROP TABLE IF EXISTS password_resets;
DROP TABLE IF EXISTS phone_verifications;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS users;
