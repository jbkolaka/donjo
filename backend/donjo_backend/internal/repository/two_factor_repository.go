package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"donjo_backend/internal/security"
)

var (
	ErrTwoFactorNotFound = errors.New("two factor not found")
)

type TwoFactorAuth struct {
	ID          string
	UserID      string
	Secret      string
	BackupCodes string
	Enabled     bool
	Verified    bool
}

type TwoFactorRepository struct {
	db *sql.DB
}

func NewTwoFactorRepository(db *sql.DB) *TwoFactorRepository {
	return &TwoFactorRepository{db: db}
}

func (r *TwoFactorRepository) Save(ctx context.Context, tfa TwoFactorAuth) error {
	secretEnc, err := security.Field(tfa.Secret)
	if err != nil {
		return fmt.Errorf("encrypt 2fa secret: %w", err)
	}
	backupEnc, err := security.Field(tfa.BackupCodes)
	if err != nil {
		return fmt.Errorf("encrypt backup codes: %w", err)
	}

	_, err = r.db.ExecContext(ctx, `
		INSERT INTO two_factor_auth (user_id, secret, backup_codes, enabled, verified)
		VALUES (?, ?, ?, ?, ?)
		ON CONFLICT(user_id) DO UPDATE SET
			secret = excluded.secret,
			backup_codes = excluded.backup_codes,
			enabled = excluded.enabled,
			verified = excluded.verified`,
		tfa.UserID, secretEnc, backupEnc, boolInt(tfa.Enabled), boolInt(tfa.Verified),
	)
	if err != nil {
		return fmt.Errorf("save two factor: %w", err)
	}
	return nil
}

func (r *TwoFactorRepository) GetByUserID(ctx context.Context, userID string) (*TwoFactorAuth, error) {
	var (
		tfa      TwoFactorAuth
		secret   string
		backup   string
		enabled  int
		verified int
	)
	err := r.db.QueryRowContext(ctx,
		`SELECT id, user_id, secret, backup_codes, enabled, verified
		 FROM two_factor_auth WHERE user_id = ?`, userID,
	).Scan(&tfa.ID, &tfa.UserID, &secret, &backup, &enabled, &verified)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrTwoFactorNotFound
		}
		return nil, err
	}

	if tfa.Secret, err = security.Decrypt(secret); err != nil {
		return nil, fmt.Errorf("decrypt 2fa secret: %w", err)
	}
	if tfa.BackupCodes, err = security.Decrypt(backup); err != nil {
		return nil, fmt.Errorf("decrypt backup codes: %w", err)
	}
	tfa.Enabled = enabled == 1
	tfa.Verified = verified == 1
	return &tfa, nil
}

func (r *TwoFactorRepository) Delete(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM two_factor_auth WHERE user_id = ?`, userID)
	return err
}

func boolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}
