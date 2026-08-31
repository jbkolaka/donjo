package auth

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"donjo_backend/internal/models"
	"donjo_backend/internal/repository"
	"donjo_backend/internal/totp"
	"donjo_backend/internal/uploads"
)

type Handler struct {
	svc           *Service
	uploadDir     string
	publicBaseURL string
}

func NewHandler(svc *Service, uploadDir, publicBaseURL string) *Handler {
	return &Handler{svc: svc, uploadDir: uploadDir, publicBaseURL: publicBaseURL}
}

func (h *Handler) Register(c *gin.Context) {
	var req models.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.svc.Register(c.Request.Context(), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrEmailTaken):
			c.JSON(http.StatusConflict, gin.H{"error": "email already registered"})
		case errors.Is(err, ErrUsernameTaken):
			c.JSON(http.StatusConflict, gin.H{"error": "username already taken"})
		case errors.Is(err, ErrPhoneTaken):
			c.JSON(http.StatusConflict, gin.H{"error": "phone already registered"})
		case errors.Is(err, ErrInvalidDOB):
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid date of birth, use YYYY-MM-DD"})
		case errors.Is(err, ErrUnderage):
			c.JSON(http.StatusBadRequest, gin.H{"error": "you must be at least 13 years old"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusCreated, user)
}

func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, tokens, err := h.svc.Login(c.Request.Context(), req.Email, req.Password, req.TwoFactorCode, deviceFromRequest(c))
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidCredentials),
			errors.Is(err, ErrInvalid2FACode),
			errors.Is(err, Err2FARequired):
			c.JSON(http.StatusOK, gin.H{"tfa_required": true})
		case errors.Is(err, ErrAccountLocked):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "too many failed attempts, try again later"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

func (h *Handler) Me(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	user, err := h.svc.GetByID(c.Request.Context(), userID)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func (h *Handler) UploadProfileImage(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, uploads.MaxImageBytes)
	fileHeader, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "image file ('image') is required"})
		return
	}
	if fileHeader.Size > uploads.MaxImageBytes {
		c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "image too large"})
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not read upload"})
		return
	}
	defer file.Close()

	urlPath, err := uploads.Save(file, h.uploadDir)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	cur, err := h.svc.GetByID(c.Request.Context(), userID)
	if err == nil && cur.ProfileImage != nil {
		if rel, ok := uploadRelative(*cur.ProfileImage); ok {
			_ = uploads.Remove(h.uploadDir, rel)
		}
	}

	publicURL := uploads.PublicURL(h.publicBaseURL, urlPath)
	if err := h.svc.UpdateProfileImage(c.Request.Context(), userID, publicURL); err != nil {
		if errors.Is(err, ErrUserNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"profile_image": publicURL})
}

func uploadRelative(raw string) (string, bool) {
	if idx := strings.LastIndex(raw, "/uploads/"); idx >= 0 {
		return raw[idx:], true
	}
	return "", false
}

func (h *Handler) Setup2FA(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	user, err := h.svc.GetByID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	secret, otpauthURL, err := h.svc.Setup2FA(c.Request.Context(), userID, user.Email)
	if err != nil {
		switch {
		case errors.Is(err, Err2FAAlreadyEnabled):
			c.JSON(http.StatusConflict, gin.H{"error": "two-factor authentication is already enabled"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"otpauth_url": otpauthURL,
		"secret":      secret,
		"issuer":      totp.DefaultIssuer,
		"period":      totp.DefaultPeriod,
		"digits":      totp.DefaultDigits,
	})
}

func (h *Handler) Verify2FA(c *gin.Context) {
	var req verify2FARequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	if err := h.svc.Verify2FA(c.Request.Context(), userID, req.Code); err != nil {
		switch {
		case errors.Is(err, ErrInvalid2FACode):
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid two-factor authentication code"})
		case errors.Is(err, Err2FANotSetup):
			c.JSON(http.StatusBadRequest, gin.H{"error": "two-factor authentication is not set up"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"enabled": true})
}

func (h *Handler) Disable2FA(c *gin.Context) {
	var req verify2FARequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	if err := h.svc.Disable2FA(c.Request.Context(), userID, req.Code); err != nil {
		switch {
		case errors.Is(err, ErrInvalid2FACode):
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid two-factor authentication code"})
		case errors.Is(err, Err2FANotSetup):
			c.JSON(http.StatusBadRequest, gin.H{"error": "two-factor authentication is not set up"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"enabled": false})
}

func (h *Handler) Status2FA(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	enabled, err := h.svc.Is2FAEnabled(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"enabled": enabled})
}

type verify2FARequest struct {
	Code string `json:"code" binding:"required"`
}

func (h *Handler) Refresh(c *gin.Context) {
	var req refreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.RefreshToken == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "refresh_token is required"})
		return
	}

	tokens, err := h.svc.Refresh(c.Request.Context(), req.RefreshToken, deviceFromRequest(c))
	if err != nil {
		if errors.Is(err, ErrInvalidRefreshToken) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired refresh token"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, tokens)
}

func (h *Handler) Logout(c *gin.Context) {
	var req refreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.RefreshToken == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "refresh_token is required"})
		return
	}

	if err := h.svc.Logout(c.Request.Context(), req.RefreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "logged out"})
}

func (h *Handler) LogoutAll(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	if err := h.svc.LogoutAll(c.Request.Context(), userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "logged out of all sessions"})
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func (h *Handler) RequestPasswordReset(c *gin.Context) {
	var req models.PasswordResetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email is required"})
		return
	}

	if _, err := h.svc.RequestPasswordReset(c.Request.Context(), req.Email); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "if that email exists, a reset link has been sent"})
}

func (h *Handler) ResetPassword(c *gin.Context) {
	var req models.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Token == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "token is required"})
		return
	}

	if err := h.svc.ResetPassword(c.Request.Context(), req.Token, req.NewPassword); err != nil {
		switch {
		case errors.Is(err, ErrWeakPassword):
			c.JSON(http.StatusBadRequest, gin.H{"error": "password must be at least 8 characters"})
		case errors.Is(err, ErrInvalidResetToken):
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired reset token"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "password updated"})
}

func (h *Handler) ListSessions(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	sessions, err := h.svc.ListSessions(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"sessions": sessions})
}

func (h *Handler) RevokeSession(c *gin.Context) {
	userID := UserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	sessionID := c.Param("id")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "session id is required"})
		return
	}

	if err := h.svc.RevokeSession(c.Request.Context(), userID, sessionID); err != nil {
		if errors.Is(err, ErrSessionNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "session not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "session revoked"})
}

func deviceFromRequest(c *gin.Context) repository.RefreshDevice {
	ua := c.GetHeader("User-Agent")
	browser, osName, devType := parseUserAgent(ua)
	return repository.RefreshDevice{
		DeviceName: ua,
		DeviceType: devType,
		Browser:    browser,
		OS:         osName,
		IPAddress:  c.ClientIP(),
	}
}

func parseUserAgent(ua string) (browser, os, deviceType string) {
	ua = strings.ToLower(ua)
	switch {
	case strings.Contains(ua, "edg/"):
		browser = "Edge"
	case strings.Contains(ua, "firefox/"):
		browser = "Firefox"
	case strings.Contains(ua, "chrome/"):
		browser = "Chrome"
	case strings.Contains(ua, "safari/"):
		browser = "Safari"
	}
	switch {
	case strings.Contains(ua, "windows"):
		os = "Windows"
	case strings.Contains(ua, "mac os"):
		os = "macOS"
	case strings.Contains(ua, "android"):
		os = "Android"
	case strings.Contains(ua, "linux"):
		os = "Linux"
	case strings.Contains(ua, "iphone") || strings.Contains(ua, "ipad"):
		os = "iOS"
	}
	switch {
	case strings.Contains(ua, "mobi") || strings.Contains(ua, "android"):
		deviceType = "mobile"
	case strings.Contains(ua, "tablet") || strings.Contains(ua, "ipad"):
		deviceType = "tablet"
	default:
		deviceType = "desktop"
	}
	return
}
