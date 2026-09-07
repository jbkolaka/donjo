DROP TRIGGER IF EXISTS update_refunds_updated_at;
DROP TRIGGER IF EXISTS update_escrows_updated_at;
DROP TRIGGER IF EXISTS update_transactions_updated_at;

DROP TABLE IF EXISTS mpesa_callbacks;
DROP TABLE IF EXISTS wallet_entries;
DROP TABLE IF EXISTS refunds;
DROP TABLE IF EXISTS escrows;
DROP TABLE IF EXISTS transactions;