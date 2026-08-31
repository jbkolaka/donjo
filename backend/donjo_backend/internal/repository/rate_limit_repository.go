package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

type RateLimitRepository struct {
	db *sql.DB
}

func NewRateLimitRepository(db *sql.DB) *RateLimitRepository {
	return &RateLimitRepository{db: db}
}

func (r *RateLimitRepository) Attempt(ctx context.Context, key, action string, window time.Duration, t time.Time) (int, error) {
	bucket := windowBucket(window, t)
	var n int
	err := r.db.QueryRowContext(ctx,
		`SELECT attempts FROM rate_limits WHERE key = ? AND action = ? AND window_start = ?`,
		key, action, bucket,
	).Scan(&n)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return 0, nil
		}
		return 0, err
	}
	return n, nil
}

func (r *RateLimitRepository) Increment(ctx context.Context, key, action string, window time.Duration, t time.Time) (int, error) {
	bucket := windowBucket(window, t)
	now := time.Now().Format("2006-01-02 15:04:05")

	res, err := r.db.ExecContext(ctx, `
		INSERT INTO rate_limits (key, action, window_start, attempts, updated_at)
		VALUES (?, ?, ?, 1, ?)
		ON CONFLICT(key, action, window_start) DO UPDATE SET
			attempts = attempts + 1,
			updated_at = excluded.updated_at`,
		key, action, bucket, now,
	)
	if err != nil {
		return 0, fmt.Errorf("increment rate limit: %w", err)
	}

	_ = res
	return r.Attempt(ctx, key, action, window, t)
}

func windowBucket(window time.Duration, t time.Time) string {
	secs := int64(window.Seconds())
	if secs < 1 {
		secs = 1
	}
	start := t.Unix() - (t.Unix() % secs)
	return time.Unix(start, 0).UTC().Format("2006-01-02 15:04:05")
}

func (r *RateLimitRepository) Reset(ctx context.Context, key, action string) error {
	_, err := r.db.ExecContext(ctx,
		`DELETE FROM rate_limits WHERE key = ? AND action = ?`,
		key, action,
	)
	return err
}
