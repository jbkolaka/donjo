package auth

import (
	"context"
	"time"

	"donjo_backend/internal/repository"
)

const (
	failedLoginMax  = 5
	lockWindow      = 15 * time.Minute
	rateLimitMax    = 20
	rateLimitWindow = 15 * time.Minute
)

type LoginThrottle struct {
	users   *repository.UserRepository
	ratelmt *repository.RateLimitRepository
}

func NewLoginThrottle(users *repository.UserRepository, ratelmt *repository.RateLimitRepository) *LoginThrottle {
	return &LoginThrottle{users: users, ratelmt: ratelmt}
}

func (t *LoginThrottle) IdentifierLocked(ctx context.Context, identifier string) (bool, time.Duration) {
	n, err := t.ratelmt.Attempt(ctx, "login:"+identifier, "login", rateLimitWindow, time.Now())
	if err != nil || n < rateLimitMax {
		return false, 0
	}
	return true, rateLimitWindow
}

func (t *LoginThrottle) AccountLocked(lockedUntil *time.Time) bool {
	if lockedUntil == nil {
		return false
	}
	return time.Now().Before(*lockedUntil)
}

func (t *LoginThrottle) RecordIdentifierFailure(ctx context.Context, identifier string) {
	_, _ = t.ratelmt.Increment(ctx, "login:"+identifier, "login", rateLimitWindow, time.Now())
}

func (t *LoginThrottle) RecordUserFailure(ctx context.Context, userID string) error {
	if err := t.users.RecordFailedLogin(ctx, userID); err != nil {
		return err
	}

	curr, err := t.users.FailedLoginCount(ctx, userID)
	if err != nil {
		return err
	}
	if curr >= failedLoginMax {
		return t.users.ApplyLockout(ctx, userID, time.Now().Add(lockWindow))
	}
	return nil
}

func (t *LoginThrottle) Reset(ctx context.Context, userID, identifier string) {
	_ = t.users.ClearLockout(ctx, userID)
	_ = t.ratelmt.Reset(ctx, "login:"+identifier, "login")
}
