package auth

import (
	"context"
	"database/sql"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	_ "github.com/mattn/go-sqlite3"

	"donjo_backend/internal/models"
	"donjo_backend/internal/repository"
	"donjo_backend/internal/totp"
)

func newTestService(t *testing.T, schemaPath string) (*Service, context.Context) {
	t.Helper()

	t.Setenv("DATA_ENCRYPTION_KEY", "7327159b94650e734786083df41fd40c0765bdc238c688cad2ac27952281a222")
	t.Setenv("DATA_INDEX_KEY", "a6227c183126e70f062aa0cc3b3925d2cc64ce79aac93119d9d76b3d9199f0ee")

	db, err := sql.Open("sqlite3", filepath.Join(t.TempDir(), "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	db.SetMaxOpenConns(1)

	content, err := os.ReadFile(schemaPath)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(string(content)); err != nil {
		t.Fatal(err)
	}

	svc := NewService(
		repository.NewUserRepository(db),
		repository.NewTwoFactorRepository(db),
		repository.NewRefreshTokenRepository(db),
		repository.NewPasswordResetRepository(db),
		repository.NewRateLimitRepository(db),
		NewTokenManager(),
		nil,
	)

	return svc, context.Background()
}

func registerTestUser(t *testing.T, svc *Service, ctx context.Context) *models.User {
	t.Helper()
	user, err := svc.Register(ctx, models.CreateUserRequest{
		Email:       "flow@donjo.com",
		Password:    "password123",
		FullName:    "Flow User",
		Username:    "flowuser",
		DateOfBirth: "2000-01-01",
		PhoneNumber: "254712121212",
	})
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	return user
}

func Test2FALifecycle(t *testing.T) {
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	user := registerTestUser(t, svc, ctx)

	enabled, err := svc.Is2FAEnabled(ctx, user.ID)
	if err != nil || enabled {
		t.Fatalf("expected 2FA disabled, got enabled=%v err=%v", enabled, err)
	}

	secret, otpauthURL, err := svc.Setup2FA(ctx, user.ID, user.Email)
	if err != nil {
		t.Fatalf("setup: %v", err)
	}
	if secret == "" || otpauthURL == "" {
		t.Fatalf("expected secret and url")
	}

	enabled, _ = svc.Is2FAEnabled(ctx, user.ID)
	if enabled {
		t.Fatal("2FA should not be enabled before verify")
	}

	if err := svc.Verify2FA(ctx, user.ID, "123456"); err == nil {
		t.Fatal("expected invalid code error")
	}

	code := currentCode(t, secret)
	if err := svc.Verify2FA(ctx, user.ID, code); err != nil {
		t.Fatalf("verify with correct code: %v", err)
	}
	enabled, _ = svc.Is2FAEnabled(ctx, user.ID)
	if !enabled {
		t.Fatal("2FA should be enabled after verify")
	}

	_, _, err = svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{})
	if !errors.Is(err, Err2FARequired) {
		t.Fatalf("expected Err2FARequired, got %v", err)
	}

	_, _, err = svc.Login(ctx, "flow@donjo.com", "password123", "000000", repository.RefreshDevice{})
	if !errors.Is(err, ErrInvalid2FACode) {
		t.Fatalf("expected ErrInvalid2FACode, got %v", err)
	}

	_, tokens, err := svc.Login(ctx, "flow@donjo.com", "password123", code, repository.RefreshDevice{})
	if err != nil {
		t.Fatalf("login with code: %v", err)
	}
	if tokens.AccessToken == "" {
		t.Fatal("expected access token")
	}

	if err := svc.Disable2FA(ctx, user.ID, "000000"); err == nil {
		t.Fatal("expected invalid code when disabling")
	}
	if err := svc.Disable2FA(ctx, user.ID, currentCode(t, secret)); err != nil {
		t.Fatalf("disable: %v", err)
	}
	enabled, _ = svc.Is2FAEnabled(ctx, user.ID)
	if enabled {
		t.Fatal("2FA should be disabled")
	}
	if _, _, err := svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{}); err != nil {
		t.Fatalf("login after disable should not need code, got %v", err)
	}
}

func currentCode(t *testing.T, secret string) string {
	t.Helper()
	code, err := totp.Code(secret, time.Now(), totp.AlgSHA1, totp.DefaultDigits, totp.DefaultPeriod)
	if err != nil {
		t.Fatal(err)
	}
	return code
}

func TestRefreshRotationAndLogout(t *testing.T) {
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	registerTestUser(t, svc, ctx)

	_, tokens, err := svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{})
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if tokens.RefreshToken == "" {
		t.Fatal("expected a refresh token on login")
	}
	firstRefresh := tokens.RefreshToken

	newTokens, err := svc.Refresh(ctx, firstRefresh, repository.RefreshDevice{})
	if err != nil {
		t.Fatalf("refresh: %v", err)
	}
	if newTokens.RefreshToken == "" || newTokens.RefreshToken == firstRefresh {
		t.Fatalf("expected a new refresh token, got %q", newTokens.RefreshToken)
	}

	if _, err := svc.Refresh(ctx, firstRefresh, repository.RefreshDevice{}); !errors.Is(err, ErrInvalidRefreshToken) {
		t.Fatalf("expected reused refresh token to fail, got %v", err)
	}

	if err := svc.Logout(ctx, newTokens.RefreshToken); err != nil {
		t.Fatalf("logout: %v", err)
	}
	if _, err := svc.Refresh(ctx, newTokens.RefreshToken, repository.RefreshDevice{}); !errors.Is(err, ErrInvalidRefreshToken) {
		t.Fatalf("expected logged-out refresh token to fail, got %v", err)
	}

	if _, err := svc.Refresh(ctx, "not-a-real-token", repository.RefreshDevice{}); !errors.Is(err, ErrInvalidRefreshToken) {
		t.Fatalf("expected garbage token to fail, got %v", err)
	}
}

func TestRefreshReuseReplayRevokesAllSessions(t *testing.T) {
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	registerTestUser(t, svc, ctx)

	_, tokens, err := svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{})
	if err != nil {
		t.Fatalf("login: %v", err)
	}

	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if _, err := svc.Refresh(ctx, tokens.RefreshToken, repository.RefreshDevice{}); err != nil {
		t.Fatalf("first refresh: %v", err)
	}

	if _, err := svc.Refresh(ctx, tokens.RefreshToken, repository.RefreshDevice{}); !errors.Is(err, ErrInvalidRefreshToken) {
		t.Fatalf("expected replay of rotated token to fail, got %v", err)
	}

	_, tok2, err := svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{})
	if err != nil {
		t.Fatalf("re-login: %v", err)
	}
	if _, err := svc.Refresh(ctx, tok2.RefreshToken, repository.RefreshDevice{}); err != nil {
		t.Fatalf("expected post-replay refresh to work, got %v", err)
	}
}

func TestPasswordResetFlow(t *testing.T) {
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	registerTestUser(t, svc, ctx)

	raw, err := svc.RequestPasswordReset(ctx, "flow@donjo.com")
	if err != nil {
		t.Fatalf("request reset: %v", err)
	}
	if raw == "" {
		t.Fatal("expected a reset token for a known account")
	}

	unknown, err := svc.RequestPasswordReset(ctx, "ghost@donjo.com")
	if err != nil {
		t.Fatalf("request reset for unknown email should not error, got %v", err)
	}
	if unknown != "" {
		t.Fatalf("expected empty token for unknown email, got %v", unknown)
	}

	if err := svc.ResetPassword(ctx, "bogus-token", "newpassword123"); !errors.Is(err, ErrInvalidResetToken) {
		t.Fatalf("expected invalid reset token error, got %v", err)
	}

	if err := svc.ResetPassword(ctx, raw, "newpassword123"); err != nil {
		t.Fatalf("reset password: %v", err)
	}

	if err := svc.ResetPassword(ctx, raw, "anotherpassword"); !errors.Is(err, ErrInvalidResetToken) {
		t.Fatalf("expected reused reset token to fail, got %v", err)
	}

	if _, _, err := svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{}); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected old password to fail, got %v", err)
	}
	if _, _, err := svc.Login(ctx, "flow@donjo.com", "newpassword123", "", repository.RefreshDevice{}); err != nil {
		t.Fatalf("expected new password to work, got %v", err)
	}

	if err := svc.ResetPassword(ctx, "made-up-token", "brandnewpass1"); !errors.Is(err, ErrInvalidResetToken) {
		t.Fatalf("expected invalid reset token error for bogus token, got %v", err)
	}
}

func TestLoginLockout(t *testing.T) {
	t.Setenv("DATA_ENCRYPTION_KEY", "7327159b94650e734786083df41fd40c0765bdc238c688cad2ac27952281a222")
	t.Setenv("DATA_INDEX_KEY", "a6227c183126e70f062aa0cc3b3925d2cc64ce79aac93119d9d76b3d9199f0ee")

	db, err := sql.Open("sqlite3", filepath.Join(t.TempDir(), "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	db.SetMaxOpenConns(1)
	t.Cleanup(func() { db.Close() })

	schema, err := os.ReadFile("../../migrations/001_auth_schema.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(string(schema)); err != nil {
		t.Fatal(err)
	}

	makeSvc := func() *Service {
		return NewService(
			repository.NewUserRepository(db),
			repository.NewTwoFactorRepository(db),
			repository.NewRefreshTokenRepository(db),
			repository.NewPasswordResetRepository(db),
			repository.NewRateLimitRepository(db),
			NewTokenManager(),
			nil,
		)
	}

	svc := makeSvc()
	ctx := context.Background()
	registerTestUser(t, svc, ctx)

	for i := 0; i < failedLoginMax; i++ {
		_, _, err := svc.Login(ctx, "flow@donjo.com", "wrong-password", "", repository.RefreshDevice{})
		if !errors.Is(err, ErrInvalidCredentials) {
			t.Fatalf("attempt %d: expected ErrInvalidCredentials, got %v", i, err)
		}
	}

	_, _, err = svc.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{})
	if !errors.Is(err, ErrAccountLocked) {
		t.Fatalf("expected ErrAccountLocked, got %v", err)
	}

	svc2 := makeSvc()
	_, _, err = svc2.Login(ctx, "flow@donjo.com", "password123", "", repository.RefreshDevice{})
	if !errors.Is(err, ErrAccountLocked) {
		t.Fatalf("expected persisted ErrAccountLocked across service instance, got %v", err)
	}
}

func TestSessionsListAndRevoke(t *testing.T) {
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	user := registerTestUser(t, svc, ctx)

	dev := repository.RefreshDevice{
		DeviceName: "Pyramid", DeviceType: "desktop", Browser: "firefox",
		OS: "linux", IPAddress: "10.0.0.1", Location: "Nairobi",
	}
	_, tokens, err := svc.Login(ctx, "flow@donjo.com", "password123", "", dev)
	if err != nil {
		t.Fatalf("login: %v", err)
	}

	sessions, err := svc.ListSessions(ctx, user.ID)
	if err != nil {
		t.Fatalf("list sessions: %v", err)
	}
	if len(sessions) != 1 {
		t.Fatalf("expected 1 session, got %d", len(sessions))
	}
	s := sessions[0]
	if s.Browser != "firefox" || s.OS != "linux" || s.Location != "Nairobi" || s.DeviceName != "Pyramid" {
		t.Fatalf("device info not captured: %+v", s)
	}

	if _, _, err := svc.Login(ctx, "flow@donjo.com", "password123", "", dev); err != nil {
		t.Fatalf("second login: %v", err)
	}
	sessions, _ = svc.ListSessions(ctx, user.ID)
	if len(sessions) != 2 {
		t.Fatalf("expected 2 sessions after second login, got %d", len(sessions))
	}

	if err := svc.RevokeSession(ctx, user.ID, s.ID); err != nil {
		t.Fatalf("revoke session: %v", err)
	}
	sessions, _ = svc.ListSessions(ctx, user.ID)
	foundRevoked := false
	for _, s2 := range sessions {
		if s2.ID == s.ID && s2.Revoked {
			foundRevoked = true
		}
	}
	if !foundRevoked {
		t.Fatalf("expected session %s to be flagged revoked", s.ID)
	}

	if err := svc.RevokeSession(ctx, user.ID, "does-not-exist"); !errors.Is(err, ErrSessionNotFound) {
		t.Fatalf("expected ErrSessionNotFound, got %v", err)
	}

	if _, err := svc.Refresh(ctx, tokens.RefreshToken, dev); !errors.Is(err, ErrInvalidRefreshToken) {
		t.Fatalf("expected revoked refresh token to be invalid, got %v", err)
	}
}
