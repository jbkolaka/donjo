package auth

import (
	"context"
	"errors"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"donjo_backend/internal/mailer"
	"donjo_backend/internal/models"
	"donjo_backend/internal/repository"
	"donjo_backend/internal/security"
	"donjo_backend/internal/totp"
)

var (
	ErrInvalidCredentials  = errors.New("invalid credentials")
	ErrUsernameTaken       = errors.New("username already taken")
	ErrEmailTaken          = errors.New("email already taken")
	ErrPhoneTaken          = errors.New("phone already registered")
	ErrInvalidDOB          = errors.New("invalid date of birth")
	ErrUnderage            = errors.New("you must be at least 13 years old")
	ErrUserNotFound        = errors.New("user not found")
	ErrInvalidRefreshToken = errors.New("invalid or expired refresh token")
	ErrAccountLocked       = errors.New("account temporarily locked, try again later")
	Err2FANotSetup         = errors.New("two-factor authentication is not set up")
	Err2FAAlreadyEnabled   = errors.New("two-factor authentication is already enabled")
	Err2FAAlreadySetup     = errors.New("two-factor authentication is already configured")
	ErrInvalid2FACode      = errors.New("invalid two-factor authentication code")
	Err2FARequired         = errors.New("two-factor authentication code required")
	ErrWeakPassword        = errors.New("password must be at least 8 characters")
	ErrInvalidResetToken   = errors.New("invalid or expired reset token")
	ErrSessionNotFound     = errors.New("session not found")
)

var dummyPasswordHash = func() string {
	h, err := bcrypt.GenerateFromPassword([]byte("donjo-timing-equalizer"), bcrypt.DefaultCost)
	if err != nil {
		panic(err)
	}
	return string(h)
}()

type Service struct {
	users     *repository.UserRepository
	twoFactor *repository.TwoFactorRepository
	refresh   *repository.RefreshTokenRepository
	passReset *repository.PasswordResetRepository
	token     *TokenManager
	throttle  *LoginThrottle
	mail      mailer.Sender
}

func NewService(users *repository.UserRepository, twoFactor *repository.TwoFactorRepository, refresh *repository.RefreshTokenRepository, passReset *repository.PasswordResetRepository, ratelmt *repository.RateLimitRepository, token *TokenManager, mail mailer.Sender) *Service {
	return &Service{
		users:     users,
		twoFactor: twoFactor,
		refresh:   refresh,
		passReset: passReset,
		token:     token,
		throttle:  NewLoginThrottle(users, ratelmt),
		mail:      mail,
	}
}

func (s *Service) Register(ctx context.Context, req models.CreateUserRequest) (*models.User, error) {
	dob, err := time.Parse("2006-01-02", req.DateOfBirth)
	if err != nil {
		return nil, ErrInvalidDOB
	}

	if time.Since(dob) < 13*365*24*time.Hour {
		return nil, ErrUnderage
	}

	emailTaken, err := s.users.EmailExists(ctx, req.Email)
	if err != nil {
		return nil, err
	}
	if emailTaken {
		return nil, ErrEmailTaken
	}

	phoneTaken, err := s.users.PhoneExists(ctx, req.PhoneNumber)
	if err != nil {
		return nil, err
	}
	if phoneTaken {
		return nil, ErrPhoneTaken
	}

	usernameTaken, err := s.users.UsernameExists(ctx, req.Username)
	if err != nil {
		return nil, err
	}
	if usernameTaken {
		return nil, ErrUsernameTaken
	}

	hash, err := hashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	user, err := s.users.Create(ctx, req, hash)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *Service) Login(ctx context.Context, email, password, code string, dev repository.RefreshDevice) (*models.User, models.TokenResponse, error) {
	if locked, _ := s.throttle.IdentifierLocked(ctx, email); locked {
		return nil, models.TokenResponse{}, ErrAccountLocked
	}

	user, err := s.users.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, repository.ErrUserNotFound) {
			_ = bcrypt.CompareHashAndPassword([]byte(dummyPasswordHash), []byte(password))
			s.throttle.RecordIdentifierFailure(ctx, email)
			return nil, models.TokenResponse{}, ErrInvalidCredentials
		}
		return nil, models.TokenResponse{}, err
	}

	if s.throttle.AccountLocked(user.LockedUntil) {
		return nil, models.TokenResponse{}, ErrAccountLocked
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		s.throttle.RecordIdentifierFailure(ctx, email)
		_ = s.throttle.RecordUserFailure(ctx, user.ID)
		return nil, models.TokenResponse{}, ErrInvalidCredentials
	}

	tfaEnabled, err := s.Is2FAEnabled(ctx, user.ID)
	if err != nil {
		return nil, models.TokenResponse{}, err
	}

	if tfaEnabled {
		ok, err := s.Validate2FACode(ctx, user.ID, code)
		if err != nil {
			return nil, models.TokenResponse{}, err
		}
		if !ok {
			s.throttle.RecordIdentifierFailure(ctx, email)
			_ = s.throttle.RecordUserFailure(ctx, user.ID)
			return nil, models.TokenResponse{}, ErrInvalid2FACode
		}
	}

	s.throttle.Reset(ctx, user.ID, email)

	tokenResp, err := s.issueTokens(ctx, user, dev)
	if err != nil {
		return nil, models.TokenResponse{}, err
	}

	return user, tokenResp, nil
}

func (s *Service) Refresh(ctx context.Context, rawToken string, dev repository.RefreshDevice) (models.TokenResponse, error) {
	hash := security.TokenHash(rawToken)
	t, err := s.refresh.FindByHash(ctx, hash)
	if err != nil {
		if errors.Is(err, repository.ErrRefreshTokenNotFound) {
			return models.TokenResponse{}, ErrInvalidRefreshToken
		}
		return models.TokenResponse{}, err
	}

	if t.Revoked {
		if t.RevokedReason == "rotated" || t.RevokedReason == "reuse" {
			_ = s.refresh.RevokeAllForUser(ctx, t.UserID)
		}
		return models.TokenResponse{}, ErrInvalidRefreshToken
	}

	if time.Now().After(t.ExpiresAt) {
		return models.TokenResponse{}, ErrInvalidRefreshToken
	}

	user, err := s.users.FindByID(ctx, t.UserID)
	if err != nil {
		return models.TokenResponse{}, ErrInvalidRefreshToken
	}

	if err := s.refresh.Revoke(ctx, hash, "rotated"); err != nil {
		return models.TokenResponse{}, err
	}

	return s.issueTokens(ctx, user, dev)
}

func (s *Service) Logout(ctx context.Context, rawToken string) error {
	return s.refresh.Revoke(ctx, security.TokenHash(rawToken), "logout")
}

func (s *Service) LogoutAll(ctx context.Context, userID string) error {
	return s.refresh.RevokeAllForUser(ctx, userID)
}

type Session struct {
	ID           string     `json:"id"`
	DeviceName   string     `json:"device_name,omitempty"`
	DeviceType   string     `json:"device_type,omitempty"`
	Browser      string     `json:"browser,omitempty"`
	OS           string     `json:"os,omitempty"`
	IPAddress    string     `json:"ip_address,omitempty"`
	Location     string     `json:"location,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	LastUsedAt   *time.Time `json:"last_used_at,omitempty"`
	ExpiresAt    time.Time  `json:"expires_at"`
	Revoked      bool       `json:"revoked"`
	RevokedAt    *time.Time `json:"revoked_at,omitempty"`
	RevokeReason string     `json:"revoke_reason,omitempty"`
}

func (s *Service) ListSessions(ctx context.Context, userID string) ([]Session, error) {
	toks, err := s.refresh.ListByUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	out := make([]Session, 0, len(toks))
	for _, t := range toks {
		out = append(out, Session{
			ID:           t.ID,
			DeviceName:   t.DeviceName,
			DeviceType:   t.DeviceType,
			Browser:      t.Browser,
			OS:           t.OS,
			IPAddress:    t.IPAddress,
			Location:     t.Location,
			CreatedAt:    t.CreatedAt,
			LastUsedAt:   t.LastUsed,
			ExpiresAt:    t.ExpiresAt,
			Revoked:      t.Revoked,
			RevokedAt:    t.RevokedAt,
			RevokeReason: t.RevokedReason,
		})
	}
	return out, nil
}

func (s *Service) RevokeSession(ctx context.Context, userID, sessionID string) error {
	ok, err := s.refresh.RevokeByID(ctx, userID, sessionID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrSessionNotFound
	}
	return nil
}

func (s *Service) issueTokens(ctx context.Context, user *models.User, dev repository.RefreshDevice) (models.TokenResponse, error) {
	access, err := s.token.GenerateAccess(user.ID, user.Email)
	if err != nil {
		return models.TokenResponse{}, err
	}

	rawRefresh, err := security.RandomToken(32)
	if err != nil {
		return models.TokenResponse{}, err
	}

	ttl := s.token.refreshTTL
	if _, err := s.refresh.Create(ctx, user.ID, security.TokenHash(rawRefresh), time.Now().Add(ttl), dev); err != nil {
		return models.TokenResponse{}, err
	}

	return models.TokenResponse{
		AccessToken:  access,
		RefreshToken: rawRefresh,
		ExpiresIn:    s.token.AccessTTLSeconds(),
		TokenType:    "Bearer",
	}, nil
}

func (s *Service) GetByID(ctx context.Context, id string) (*models.User, error) {
	user, err := s.users.FindByID(ctx, id)
	if errors.Is(err, repository.ErrUserNotFound) {
		return nil, ErrUserNotFound
	}
	return user, err
}

func (s *Service) UpdateProfileImage(ctx context.Context, userID, url string) error {
	ok, err := s.users.UpdateProfileImage(ctx, userID, url)
	if err != nil {
		return err
	}
	if !ok {
		return ErrUserNotFound
	}
	return nil
}

func (s *Service) RequestPasswordReset(ctx context.Context, email string) (string, error) {
	raw, err := security.RandomToken(32)
	if err != nil {
		return "", err
	}

	user, err := s.users.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, repository.ErrUserNotFound) {
			return "", nil
		}
		return "", err
	}

	if err := s.passReset.Create(ctx, user.ID, security.TokenHash(raw), time.Now().Add(1*time.Hour)); err != nil {
		return "", err
	}

	if s.mail != nil {
		link := resetLink(raw)
		subject := "Donjo password reset"
		body := "A password reset was requested for your Donjo account.\n\n" +
			"Use this link within 1 hour to set a new password:\n\n" + link + "\n\n" +
			"If you did not request this, you can safely ignore this email."
		go func() {
			_ = s.mail.Send(user.Email, subject, body)
		}()
	}

	return raw, nil
}

func resetLink(token string) string {
	base := strings.TrimRight(os.Getenv("APP_BASE_URL"), "/")
	if base == "" {
		base = "http://localhost:5173"
	}
	return base + "/reset-password?token=" + token
}

func (s *Service) ResetPassword(ctx context.Context, token, newPassword string) error {
	if len(newPassword) < 8 {
		return ErrWeakPassword
	}

	pr, err := s.passReset.FindByHash(ctx, security.TokenHash(token))
	if err != nil {
		if errors.Is(err, repository.ErrPasswordResetNotFound) {
			return ErrInvalidResetToken
		}
		return err
	}
	if pr.Used {
		return ErrInvalidResetToken
	}
	if time.Now().After(pr.ExpiresAt) {
		return ErrInvalidResetToken
	}

	hash, err := hashPassword(newPassword)
	if err != nil {
		return err
	}
	if err := s.users.UpdatePasswordHash(ctx, pr.UserID, hash); err != nil {
		return err
	}

	_ = s.passReset.InvalidateAllForUser(ctx, pr.UserID)
	_ = s.refresh.RevokeAllForUser(ctx, pr.UserID)
	return s.passReset.MarkUsed(ctx, security.TokenHash(token))
}

func (s *Service) Setup2FA(ctx context.Context, userID, email string) (secret, otpauthURL string, err error) {
	enabled, err := s.Is2FAEnabled(ctx, userID)
	if err != nil {
		return "", "", err
	}
	if enabled {
		return "", "", Err2FAAlreadyEnabled
	}

	secret, err = totp.GenerateSecret(20)
	if err != nil {
		return "", "", err
	}

	otpauthURL, err = totp.URL(secret, email, "")
	if err != nil {
		return "", "", err
	}

	tfa := repository.TwoFactorAuth{
		UserID:   userID,
		Secret:   secret,
		Enabled:  false,
		Verified: false,
	}
	if err := s.twoFactor.Save(ctx, tfa); err != nil {
		return "", "", err
	}

	return secret, otpauthURL, nil
}

func (s *Service) Verify2FA(ctx context.Context, userID, code string) error {
	tfa, err := s.twoFactor.GetByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, repository.ErrTwoFactorNotFound) {
			return Err2FANotSetup
		}
		return err
	}

	ok, err := totp.Validate(tfa.Secret, code, time.Now(), 1)
	if err != nil {
		return err
	}
	if !ok {
		return ErrInvalid2FACode
	}

	tfa.Verified = true
	tfa.Enabled = true
	return s.twoFactor.Save(ctx, *tfa)
}

func (s *Service) Disable2FA(ctx context.Context, userID, code string) error {
	tfa, err := s.twoFactor.GetByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, repository.ErrTwoFactorNotFound) {
			return Err2FANotSetup
		}
		return err
	}

	ok, err := totp.Validate(tfa.Secret, code, time.Now(), 1)
	if err != nil {
		return err
	}
	if !ok {
		return ErrInvalid2FACode
	}

	return s.twoFactor.Delete(ctx, userID)
}

func (s *Service) Is2FAEnabled(ctx context.Context, userID string) (bool, error) {
	tfa, err := s.twoFactor.GetByUserID(ctx, userID)
	if errors.Is(err, repository.ErrTwoFactorNotFound) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return tfa.Enabled, nil
}

func (s *Service) Validate2FACode(ctx context.Context, userID, code string) (bool, error) {
	if strings.TrimSpace(code) == "" {
		return false, Err2FARequired
	}

	tfa, err := s.twoFactor.GetByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, repository.ErrTwoFactorNotFound) {
			return false, Err2FANotSetup
		}
		return false, err
	}

	ok, err := totp.Validate(tfa.Secret, code, time.Now(), 1)
	if err != nil {
		return false, err
	}
	return ok, nil
}

func hashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}
