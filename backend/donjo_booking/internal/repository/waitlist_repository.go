package repository

import (
	"database/sql"
	"time"

	"donjo_booking/internal/models"
)

// WaitlistRepository tracks caller interest in events beyond the ticket cap.
type WaitlistRepository struct {
	db *sql.DB
}

func NewWaitlistRepository(db *sql.DB) *WaitlistRepository {
	return &WaitlistRepository{db: db}
}

// Join adds a caller to an event's waitlist; its UNIQUE(event_id, user_id)
// constraint turns duplicates into a re-activate instead of a new row.
func (r *WaitlistRepository) Join(e models.WaitlistEntry) error {
	id, _ := newID(r.db)
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := r.db.Exec(`INSERT INTO waitlist
		(id, event_id, user_id, ticket_type, quantity, status, created_at, updated_at)
		VALUES (?,?,?,?,?,?,?,?)
		ON CONFLICT(event_id, user_id) DO UPDATE SET
			status = 'active', ticket_type = excluded.ticket_type,
			quantity = excluded.quantity, updated_at = excluded.updated_at`,
		id, e.EventID, e.UserID, nullStr(e.TicketType), e.Quantity, "active", now, now)
	return err
}

func (r *WaitlistRepository) Leave(eventID, userID string) error {
	res, err := r.db.Exec(`UPDATE waitlist SET status = 'left', updated_at = ? WHERE event_id = ? AND user_id = ?`,
		time.Now().UTC().Format(time.RFC3339), eventID, userID)
	if err != nil {
		return err
	}
	return requireAffected(res, 1)
}

func (r *WaitlistRepository) List(eventID string) ([]*models.WaitlistEntry, error) {
	rows, err := r.db.Query(`SELECT id, event_id, user_id, ticket_type, quantity, status,
		offer_sent, offer_sent_at, offer_expires_at, booking_id, converted_at, created_at, updated_at
		FROM waitlist WHERE event_id = ? AND status = 'active' ORDER BY created_at ASC`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanWaitlist(rows)
}

func (r *WaitlistRepository) Count(eventID string) (int, error) {
	var n int
	err := r.db.QueryRow(`SELECT COUNT(1) FROM waitlist WHERE event_id = ? AND status = 'active'`, eventID).Scan(&n)
	return n, err
}

func scanWaitlist(rows *sql.Rows) ([]*models.WaitlistEntry, error) {
	var out []*models.WaitlistEntry
	for rows.Next() {
		e := &models.WaitlistEntry{}
		var tt, status sql.NullString
		var offerSentAt, offerExpiresAt, bookingID, convertedAt sql.NullString
		var created, updated string
		var offerSent int
		if err := rows.Scan(&e.ID, &e.EventID, &e.UserID, &tt, &e.Quantity, &status,
			&offerSent, &offerSentAt, &offerExpiresAt, &bookingID, &convertedAt,
			&created, &updated); err != nil {
			return nil, err
		}
		e.TicketType, e.Status = tt.String, status.String
		e.OfferSent = offerSent == 1
		e.OfferSentAt = scanTime(offerSentAt)
		e.OfferExpiresAt = scanTime(offerExpiresAt)
		e.BookingID = bookingID.String
		e.ConvertedAt = scanTime(convertedAt)
		e.CreatedAt = mustTime(created)
		e.UpdatedAt = mustTime(updated)
		out = append(out, e)
	}
	if out == nil {
		out = []*models.WaitlistEntry{}
	}
	return out, rows.Err()
}