package models

import (
	"time"
)

type User struct {
	ID                  string     `json:"id"`
	Email               string     `json:"email"`
	PasswordHash        string     `json:"-"`
	FullName            string     `json:"full_name"`
	Username            string     `json:"username"`
	DateOfBirth         string     `json:"date_of_birth"`
	PhoneNumber         string     `json:"phone_number"`
	MpesaPhoneNumber    *string    `json:"mpesa_phone_number,omitempty"`
	ProfileImage        *string    `json:"profile_image,omitempty"`
	Bio                 *string    `json:"bio,omitempty"`
	Interests           *string    `json:"interests,omitempty"`
	SocialLinks         *string    `json:"social_links,omitempty"`
	EmailVerified       bool       `json:"email_verified"`
	PhoneVerified       bool       `json:"phone_verified"`
	IdentityVerified    bool       `json:"identity_verified"`
	EmailVerifiedAt     *time.Time `json:"email_verified_at,omitempty"`
	PhoneVerifiedAt     *time.Time `json:"phone_verified_at,omitempty"`
	IdentityVerifiedAt  *time.Time `json:"identity_verified_at,omitempty"`
	AccountStatus       string     `json:"account_status"`
	IsAdmin             bool       `json:"is_admin"`
	TrustScore          int        `json:"trust_score"`
	TrustLevel          string     `json:"trust_level"`
	TwoFactorEnabled    bool       `json:"two_factor_enabled"`
	FailedLoginAttempts int        `json:"-"`
	LockedUntil         *time.Time `json:"locked_until,omitempty"`
	LastLoginAt         *time.Time `json:"last_login_at,omitempty"`
	LastLoginIP         *string    `json:"last_login_ip,omitempty"`
	LastLoginDevice     *string    `json:"last_login_device,omitempty"`
	EventsCreated       int        `json:"events_created"`
	TicketsSold         int        `json:"tickets_sold"`
	VenuesListed        int        `json:"venues_listed"`
	TotalSpent          float64    `json:"total_spent"`
	TotalEarned         float64    `json:"total_earned"`
	WalletBalance       float64    `json:"wallet_balance"`
	WalletCurrency      string     `json:"wallet_currency"`
	ReferralCode        *string    `json:"referral_code,omitempty"`
	ReferredBy          *string    `json:"referred_by,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
	DeletedAt           *time.Time `json:"deleted_at,omitempty"`
}

type CreateUserRequest struct {
	Email            string `json:"email" binding:"required,email"`
	Password         string `json:"password" binding:"required,min=8"`
	FullName         string `json:"full_name" binding:"required"`
	Username         string `json:"username" binding:"required,min=3,max=50"`
	DateOfBirth      string `json:"date_of_birth" binding:"required"`
	PhoneNumber      string `json:"phone_number" binding:"required"`
	MpesaPhoneNumber string `json:"mpesa_phone_number"`
}

type LoginRequest struct {
	Email         string `json:"email" binding:"required,email"`
	Password      string `json:"password" binding:"required"`
	TwoFactorCode string `json:"two_factor_code"`
}

type PasswordResetRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
	TokenType    string `json:"token_type"`
}
