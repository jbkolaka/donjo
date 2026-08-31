package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"donjo_backend/internal/models"
	"donjo_backend/internal/security"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

var ErrUserNotFound = errors.New("user not found")

const userColumns = `id, email, email_hash, password_hash, full_name, username, date_of_birth,
	phone_number, phone_hash, mpesa_phone_number, mpesa_hash,
	profile_image, bio, interests, social_links,
	email_verified, phone_verified, identity_verified, email_verified_at,
	phone_verified_at, identity_verified_at, account_status, is_admin,
	trust_score, trust_level, two_factor_enabled, failed_login_attempts,
	locked_until, last_login_at, last_login_ip, last_login_device,
	events_created, tickets_sold, venues_listed, total_spent, total_earned,
	wallet_balance, wallet_currency, referral_code, referred_by, created_at,
	updated_at, deleted_at`

func (r *UserRepository) Create(ctx context.Context, req models.CreateUserRequest, passwordHash string) (*models.User, error) {
	var user models.User

	emailEnc, err := security.Field(req.Email)
	if err != nil {
		return nil, fmt.Errorf("encrypt email: %w", err)
	}
	emailFp, err := security.Fingerprint(req.Email)
	if err != nil {
		return nil, fmt.Errorf("fingerprint email: %w", err)
	}

	phoneEnc, err := security.Field(req.PhoneNumber)
	if err != nil {
		return nil, fmt.Errorf("encrypt phone: %w", err)
	}
	phoneFp, err := security.Fingerprint(req.PhoneNumber)
	if err != nil {
		return nil, fmt.Errorf("fingerprint phone: %w", err)
	}

	var mpesaEnc, mpesaFp any
	if req.MpesaPhoneNumber != "" {
		me, err := security.Field(req.MpesaPhoneNumber)
		if err != nil {
			return nil, fmt.Errorf("encrypt mpesa phone: %w", err)
		}
		mf, err := security.Fingerprint(req.MpesaPhoneNumber)
		if err != nil {
			return nil, fmt.Errorf("fingerprint mpesa phone: %w", err)
		}
		mpesaEnc = me
		mpesaFp = mf
	}

	stmt := `INSERT INTO users (
		email, email_hash, password_hash, full_name, username, date_of_birth,
		phone_number, phone_hash, mpesa_phone_number, mpesa_hash
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	RETURNING ` + userColumns

	row := r.db.QueryRowContext(ctx, stmt,
		emailEnc,
		emailFp,
		passwordHash,
		req.FullName,
		req.Username,
		req.DateOfBirth,
		phoneEnc,
		phoneFp,
		mpesaEnc,
		mpesaFp,
	)

	if err := scanUser(row, &user); err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}
	return &user, nil
}

func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	fp, err := security.Fingerprint(email)
	if err != nil {
		return nil, err
	}

	var user models.User
	stmt := `SELECT ` + userColumns + ` FROM users WHERE email_hash = ? AND deleted_at IS NULL`

	row := r.db.QueryRowContext(ctx, stmt, fp)
	if err := scanUser(row, &user); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("find user by email: %w", err)
	}
	return &user, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	var user models.User
	stmt := `SELECT ` + userColumns + ` FROM users WHERE id = ? AND deleted_at IS NULL`

	row := r.db.QueryRowContext(ctx, stmt, id)
	if err := scanUser(row, &user); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("find user by id: %w", err)
	}
	return &user, nil
}

func (r *UserRepository) UsernameExists(ctx context.Context, username string) (bool, error) {
	var count int
	err := r.db.QueryRowContext(ctx,
		`SELECT COUNT(1) FROM users WHERE username = ? AND deleted_at IS NULL`, username,
	).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *UserRepository) EmailExists(ctx context.Context, email string) (bool, error) {
	fp, err := security.Fingerprint(email)
	if err != nil {
		return false, err
	}
	var count int
	err = r.db.QueryRowContext(ctx,
		`SELECT COUNT(1) FROM users WHERE email_hash = ? AND deleted_at IS NULL`, fp,
	).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *UserRepository) PhoneExists(ctx context.Context, phone string) (bool, error) {
	fp, err := security.Fingerprint(phone)
	if err != nil {
		return false, err
	}
	var count int
	err = r.db.QueryRowContext(ctx,
		`SELECT COUNT(1) FROM users WHERE phone_hash = ? AND deleted_at IS NULL`, fp,
	).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanUser(row rowScanner, u *models.User) error {
	var (
		email, emailFp, phone, phoneFp                         sql.NullString
		mpesaPhone, mpesaFp                                    sql.NullString
		profileImage, bio, interests, socialLinks              sql.NullString
		emailVerifiedAt, phoneVerifiedAt, identityVerifiedAt   sql.NullString
		lockedUntil, lastLoginAt                               sql.NullString
		lastLoginIP, lastLoginDevice, referralCode, referredBy sql.NullString
		createdAt, updatedAt, deletedAt                        sql.NullString
	)

	err := row.Scan(
		&u.ID,
		&email,
		&emailFp,
		&u.PasswordHash,
		&u.FullName,
		&u.Username,
		&u.DateOfBirth,
		&phone,
		&phoneFp,
		&mpesaPhone,
		&mpesaFp,
		&profileImage,
		&bio,
		&interests,
		&socialLinks,
		&u.EmailVerified,
		&u.PhoneVerified,
		&u.IdentityVerified,
		&emailVerifiedAt,
		&phoneVerifiedAt,
		&identityVerifiedAt,
		&u.AccountStatus,
		&u.IsAdmin,
		&u.TrustScore,
		&u.TrustLevel,
		&u.TwoFactorEnabled,
		&u.FailedLoginAttempts,
		&lockedUntil,
		&lastLoginAt,
		&lastLoginIP,
		&lastLoginDevice,
		&u.EventsCreated,
		&u.TicketsSold,
		&u.VenuesListed,
		&u.TotalSpent,
		&u.TotalEarned,
		&u.WalletBalance,
		&u.WalletCurrency,
		&referralCode,
		&referredBy,
		&createdAt,
		&updatedAt,
		&deletedAt,
	)
	if err != nil {
		return err
	}

	if email.Valid && email.String != "" {
		if dec := decryptOrEmpty(email.String); dec != "" {
			u.Email = dec
		}
	}
	if phone.Valid && phone.String != "" {
		if dec := decryptOrEmpty(phone.String); dec != "" {
			u.PhoneNumber = dec
		}
	}
	if mpesaPhone.Valid && mpesaPhone.String != "" {
		if dec := decryptOrEmpty(mpesaPhone.String); dec != "" {
			u.MpesaPhoneNumber = &dec
		}
	}

	u.ProfileImage = nullStringPtr(profileImage)
	u.Bio = nullStringPtr(bio)
	u.Interests = nullStringPtr(interests)
	u.SocialLinks = nullStringPtr(socialLinks)
	u.EmailVerifiedAt = parseTime(emailVerifiedAt)
	u.PhoneVerifiedAt = parseTime(phoneVerifiedAt)
	u.IdentityVerifiedAt = parseTime(identityVerifiedAt)
	u.LockedUntil = parseTime(lockedUntil)
	u.LastLoginAt = parseTime(lastLoginAt)
	u.LastLoginIP = nullStringPtr(lastLoginIP)
	u.LastLoginDevice = nullStringPtr(lastLoginDevice)
	u.ReferralCode = nullStringPtr(referralCode)
	u.ReferredBy = nullStringPtr(referredBy)
	u.CreatedAt = parseTimeOrZero(createdAt)
	u.UpdatedAt = parseTimeOrZero(updatedAt)
	u.DeletedAt = parseTime(deletedAt)

	return nil
}

func nullStringPtr(s sql.NullString) *string {
	if !s.Valid {
		return nil
	}
	v := s.String
	return &v
}

func (r *UserRepository) RecordFailedLogin(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE users
		SET failed_login_attempts = failed_login_attempts + 1,
		    last_failed_login = ?
		WHERE id = ?`,
		time.Now().Format("2006-01-02 15:04:05"), userID,
	)
	return err
}

func (r *UserRepository) ApplyLockout(ctx context.Context, userID string, until time.Time) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET locked_until = ? WHERE id = ?`,
		until.Format("2006-01-02 15:04:05"), userID,
	)
	return err
}

func (r *UserRepository) ClearLockout(ctx context.Context, userID string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE id = ?`,
		userID,
	)
	return err
}

func (r *UserRepository) FailedLoginCount(ctx context.Context, userID string) (int, error) {
	var n int
	err := r.db.QueryRowContext(ctx,
		`SELECT failed_login_attempts FROM users WHERE id = ?`, userID,
	).Scan(&n)
	if err != nil {
		return 0, err
	}
	return n, nil
}

func (r *UserRepository) UpdatePasswordHash(ctx context.Context, userID, passwordHash string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?`,
		passwordHash, time.Now().Format("2006-01-02 15:04:05"), userID,
	)
	if err != nil {
		return fmt.Errorf("update password: %w", err)
	}
	return nil
}

func (r *UserRepository) UpdateProfileImage(ctx context.Context, userID, url string) (bool, error) {
	res, err := r.db.ExecContext(ctx,
		`UPDATE users SET profile_image = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL`,
		url, time.Now().Format("2006-01-02 15:04:05"), userID,
	)
	if err != nil {
		return false, fmt.Errorf("update profile image: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return false, err
	}
	return n > 0, nil
}

func parseTime(s sql.NullString) *time.Time {
	if !s.Valid || s.String == "" {
		return nil
	}
	t, err := time.Parse("2006-01-02 15:04:05", strings.TrimSpace(s.String))
	if err != nil {
		return nil
	}
	return &t
}

func parseTimeOrZero(s sql.NullString) time.Time {
	if !s.Valid {
		return time.Time{}
	}
	t, err := time.Parse("2006-01-02 15:04:05", strings.TrimSpace(s.String))
	if err == nil {
		return t
	}
	if t, err2 := time.Parse(time.RFC3339, strings.TrimSpace(s.String)); err2 == nil {
		return t
	}
	return time.Time{}
}

func decryptOrEmpty(ciphertext string) string {
	dec, err := security.Decrypt(ciphertext)
	if err != nil {
		return ""
	}
	return dec
}
