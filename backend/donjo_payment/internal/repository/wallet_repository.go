package repository

import (
	"database/sql"

	"donjo_payment/internal/models"
)

// WalletRepository reads the per-user wallet ledger.
type WalletRepository struct {
	db *sql.DB
}

func NewWalletRepository(db *sql.DB) *WalletRepository {
	return &WalletRepository{db: db}
}

// ListByUser returns the user's wallet ledger, newest first. In the payment
// service the ledger mirrors what many organizers expect to see on their
// payout view; the authoritative balance still lives on donjo_backend's user
// row, kept in sync by its own consumer.
func (r *WalletRepository) ListByUser(userID string) ([]*models.WalletEntry, error) {
	rows, err := r.db.Query(`
		SELECT id, user_id, type, amount, balance_after, source_type, source_id,
		       description, reference, status, created_at
		FROM wallet_entries WHERE user_id = ? ORDER BY created_at DESC, id DESC`,
		userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*models.WalletEntry
	for rows.Next() {
		var e models.WalletEntry
		var sourceType, sourceID, description, reference sql.NullString
		var createdAt sql.NullString
		if err := rows.Scan(
			&e.ID, &e.UserID, &e.Type, &e.Amount, &e.BalanceAfter,
			&sourceType, &sourceID, &description, &reference, &e.Status, &createdAt,
		); err != nil {
			return nil, err
		}
		e.SourceType = sourceType.String
		e.SourceID = sourceID.String
		e.Description = description.String
		e.Reference = reference.String
		e.CreatedAt = mustTime(createdAt.String)
		out = append(out, &e)
	}
	if out == nil {
		out = []*models.WalletEntry{}
	}
	return out, rows.Err()
}
