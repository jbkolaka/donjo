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
	ErrRefreshTokenNotFound = errors.New("refresh token not found")
	ErrRefreshTokenRevoked  = errors.New("refresh token revoked")
	ErrRefreshTokenExpired  = errors.New("refresh token expired")
)

type RefreshToken struct {
	ID            string
	UserID        string
	TokenHash     string
	ExpiresAt     time.Time
	Revoked       bool
	RevokedAt     *time.Time
	RevokedReason string
	DeviceName    string
	DeviceType    string
	Browser       string
	OS            string
	IPAddress     string
	Location      string
	LastUsed      *time.Time
	CreatedAt     time.Time
}

type RefreshDevice struct {
	DeviceName string
	DeviceType string
	Browser    string
	OS         string
	IPAddress  string
	Location   string
}

type RefreshTokenRepository struct {
	db *sql.DB
}

func NewRefreshTokenRepository(db *sql.DB) *RefreshTokenRepository {
	return &RefreshTokenRepository{db: db}
}

const refreshTokenLayout = "2006-01-02 15:04:05"

func (r *RefreshTokenRepository) Create(ctx context.Context, userID, tokenHash string, expiresAt time.Time, dev RefreshDevice) (*RefreshToken, error) {
	var id string
	stmt := `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, revoked,
	         device_name, device_type, browser, os, ip_address, location)
	         VALUES (?, ?, ?, 0, ?, ?, ?, ?, ?, ?)
	         RETURNING id`
	if err := r.db.QueryRowContext(ctx, stmt,
		userID, tokenHash, expiresAt.Format(refreshTokenLayout),
		nullable(dev.DeviceName), nullable(dev.DeviceType), nullable(dev.Browser),
		nullable(dev.OS), nullable(dev.IPAddress), nullable(dev.Location),
	).Scan(&id); err != nil {
		return nil, fmt.Errorf("create refresh token: %w", err)
	}
	return &RefreshToken{
		ID: id, UserID: userID, TokenHash: tokenHash, ExpiresAt: expiresAt,
		DeviceName: dev.DeviceName, DeviceType: dev.DeviceType, Browser: dev.Browser,
		OS: dev.OS, IPAddress: dev.IPAddress, Location: dev.Location,
	}, nil
}

func (r *RefreshTokenRepository) FindByHash(ctx context.Context, tokenHash string) (*RefreshToken, error) {
	var (
		t             RefreshToken
		expiresAt     string
		revoked       int
		revokedAt     sql.NullString
		revokedReason sql.NullString
		devName       sql.NullString
		devType       sql.NullString
		browser       sql.NullString
		osName        sql.NullString
		ipAddr        sql.NullString
		loc           sql.NullString
		lastUsed      sql.NullString
		createdAt     string
	)
	err := r.db.QueryRowContext(ctx,
		`SELECT id, user_id, token_hash, expires_at, revoked, revoked_at, revoked_reason,
		        device_name, device_type, browser, os, ip_address, location,
		        last_used_at, created_at
		 FROM refresh_tokens WHERE token_hash = ?`, tokenHash,
	).Scan(&t.ID, &t.UserID, &t.TokenHash, &expiresAt, &revoked, &revokedAt, &revokedReason,
		&devName, &devType, &browser, &osName, &ipAddr, &loc,
		&lastUsed, &createdAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrRefreshTokenNotFound
		}
		return nil, err
	}

	t.DeviceName = devName.String
	t.DeviceType = devType.String
	t.Browser = browser.String
	t.OS = osName.String
	t.IPAddress = ipAddr.String
	t.Location = loc.String

	t.ExpiresAt, _ = time.Parse(refreshTokenLayout, expiresAt)
	t.Revoked = revoked == 1
	if revokedAt.Valid {
		if rt, err := time.Parse(refreshTokenLayout, revokedAt.String); err == nil {
			t.RevokedAt = &rt
		}
	}
	if revokedReason.Valid {
		t.RevokedReason = revokedReason.String
	}
	if lastUsed.Valid {
		if lu, err := time.Parse(refreshTokenLayout, lastUsed.String); err == nil {
			t.LastUsed = &lu
		}
	}
	t.CreatedAt, _ = time.Parse(refreshTokenLayout, createdAt)

	return &t, nil
}

func (r *RefreshTokenRepository) MarkUsed(ctx context.Context, tokenHash string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET last_used_at = ? WHERE token_hash = ?`,
		time.Now().Format(refreshTokenLayout), tokenHash,
	)
	return err
}

func (r *RefreshTokenRepository) Revoke(ctx context.Context, tokenHash, reason string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked = 1, revoked_at = ?, revoked_reason = ? WHERE token_hash = ?`,
		time.Now().Format(refreshTokenLayout), reason, tokenHash,
	)
	if err != nil {
		return fmt.Errorf("revoke refresh token: %w", err)
	}
	return nil
}

func (r *RefreshTokenRepository) RevokeAllForUser(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked = 1, revoked_at = ?, revoked_reason = 'logout_all'
		 WHERE user_id = ? AND revoked = 0`,
		time.Now().Format(refreshTokenLayout), userID,
	)
	if err != nil {
		return fmt.Errorf("revoke all refresh tokens: %w", err)
	}
	return nil
}

func (r *RefreshTokenRepository) ValidateToken(ctx context.Context, rawToken string, now time.Time) (*RefreshToken, error) {
	tokenHash := HashToken(rawToken)
	t, err := r.FindByHash(ctx, tokenHash)
	if err != nil {
		return nil, err
	}

	if t.Revoked {
		return nil, ErrRefreshTokenRevoked
	}
	if now.After(t.ExpiresAt) {
		return nil, ErrRefreshTokenExpired
	}

	if err := r.MarkUsed(ctx, tokenHash); err != nil {
		return nil, err
	}
	return t, nil
}

func HashToken(rawToken string) string {
	return security.TokenHash(rawToken)
}

func (r *RefreshTokenRepository) ListByUser(ctx context.Context, userID string) ([]RefreshToken, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT id, user_id, token_hash, expires_at, revoked, revoked_at, revoked_reason,
		        device_name, device_type, browser, os, ip_address, location,
		        last_used_at, created_at
		 FROM refresh_tokens WHERE user_id = ? ORDER BY created_at DESC`, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []RefreshToken
	for rows.Next() {
		var t RefreshToken
		var expiresAt, createdAt string
		var revoked int
		var revokedAt, revokedReason, lastUsed sql.NullString
		var devName, devType, browser, osName, ipAddr, loc sql.NullString
		if err := rows.Scan(&t.ID, &t.UserID, &t.TokenHash, &expiresAt, &revoked, &revokedAt, &revokedReason,
			&devName, &devType, &browser, &osName, &ipAddr, &loc,
			&lastUsed, &createdAt); err != nil {
			return nil, err
		}
		t.DeviceName = devName.String
		t.DeviceType = devType.String
		t.Browser = browser.String
		t.OS = osName.String
		t.IPAddress = ipAddr.String
		t.Location = loc.String
		t.ExpiresAt, _ = time.Parse(refreshTokenLayout, expiresAt)
		t.Revoked = revoked == 1
		if revokedAt.Valid {
			if rt, err := time.Parse(refreshTokenLayout, revokedAt.String); err == nil {
				t.RevokedAt = &rt
			}
		}
		if revokedReason.Valid {
			t.RevokedReason = revokedReason.String
		}
		if lastUsed.Valid {
			if lu, err := time.Parse(refreshTokenLayout, lastUsed.String); err == nil {
				t.LastUsed = &lu
			}
		}
		t.CreatedAt, _ = time.Parse(refreshTokenLayout, createdAt)
		out = append(out, t)
	}
	return out, rows.Err()
}

func (r *RefreshTokenRepository) RevokeByID(ctx context.Context, userID, id string) (bool, error) {
	res, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked = 1, revoked_at = ?, revoked_reason = 'user'
		 WHERE id = ? AND user_id = ? AND revoked = 0`,
		time.Now().Format(refreshTokenLayout), id, userID,
	)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return false, err
	}
	return n > 0, nil
}

func nullable(s string) sql.NullString {
	if s == "" {
		return sql.NullString{}
	}
	return sql.NullString{String: s, Valid: true}
}
