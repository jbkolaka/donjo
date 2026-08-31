package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"donjo_backend/internal/security"
)

var (
	ErrPasswordResetNotFound = errors.New("password reset not found")
	ErrPasswordResetUsed     = errors.New("password reset already used")
	ErrPasswordResetExpired  = errors.New("password reset expired")
)

const passwordResetLayout = "2006-01-02 15:04:05"

type PasswordResetRepository struct {
	db *sql.DB
}

func NewPasswordResetRepository(db *sql.DB) *PasswordResetRepository {
	return &PasswordResetRepository{db: db}
}

type PasswordReset struct {
	ID        string
	UserID    string
	TokenHash string
	ExpiresAt time.Time
	Used      bool
	CreatedAt time.Time
}

func (r *PasswordResetRepository) Create(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO password_resets (user_id, token, expires_at, used)
		VALUES (?, ?, ?, 0)`,
		userID, tokenHash, expiresAt.Format(passwordResetLayout),
	)
	if err != nil {
		return fmt.Errorf("create password reset: %w", err)
	}
	return nil
}

func (r *PasswordResetRepository) FindByHash(ctx context.Context, tokenHash string) (*PasswordReset, error) {
	var (
		pr        PasswordReset
		expiresAt string
		used      int
		createdAt string
	)
	err := r.db.QueryRowContext(ctx,
		`SELECT id, user_id, token, expires_at, used, created_at
		 FROM password_resets WHERE token = ?`, tokenHash,
	).Scan(&pr.ID, &pr.UserID, &pr.TokenHash, &expiresAt, &used, &createdAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrPasswordResetNotFound
		}
		return nil, err
	}
	pr.ExpiresAt, _ = time.Parse(passwordResetLayout, expiresAt)
	pr.Used = used == 1
	pr.CreatedAt, _ = time.Parse(passwordResetLayout, createdAt)
	return &pr, nil
}

func (r *PasswordResetRepository) MarkUsed(ctx context.Context, tokenHash string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE password_resets SET used = 1, used_at = ? WHERE token = ?`,
		time.Now().Format(passwordResetLayout), tokenHash,
	)
	return err
}

func (r *PasswordResetRepository) InvalidateAllForUser(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE password_resets SET used = 1, used_at = ? WHERE user_id = ? AND used = 0`,
		time.Now().Format(passwordResetLayout), userID,
	)
	return err
}

func HashResetToken(raw string) string {
	return security.TokenHash(raw)
}
