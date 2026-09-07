package auth

import (
	"errors"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const (
	ContextUserID = "auth_user_id"
	ContextEmail  = "auth_email"
)

type Claim struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

type Middleware struct {
	secret []byte
}

func NewMiddleware() *Middleware {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" || len(secret) < 32 {
		if os.Getenv("APP_ENV") == "production" {
			panic("JWT_SECRET must be set to a random value of 32+ characters in production")
		}
		secret = "donjo-dev-secret-change-me-in-production"
	}
	return &Middleware{secret: []byte(secret)}
}

func (m *Middleware) RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString := bearerToken(c.GetHeader("Authorization"))
		if tokenString == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing authorization token"})
			return
		}

		claim, err := m.Validate(tokenString)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
			return
		}

		c.Set(ContextUserID, claim.UserID)
		c.Set(ContextEmail, claim.Email)
		c.Next()
	}
}

func (m *Middleware) Validate(tokenString string) (*Claim, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claim{}, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return m.secret, nil
	}, jwt.WithValidMethods([]string{"HS256"}),
		jwt.WithIssuer("donjo"),
		jwt.WithAudience("donjo-api"),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return nil, err
	}

	claim, ok := token.Claims.(*Claim)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claim, nil
}

func UserID(c *gin.Context) string {
	v, _ := c.Get(ContextUserID)
	s, _ := v.(string)
	return s
}

func Email(c *gin.Context) string {
	v, _ := c.Get(ContextEmail)
	s, _ := v.(string)
	return s
}

func bearerToken(header string) string {
	parts := strings.SplitN(strings.TrimSpace(header), " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return strings.TrimSpace(parts[1])
}
