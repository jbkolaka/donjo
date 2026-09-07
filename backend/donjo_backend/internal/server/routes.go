package server

import (
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"donjo_backend/internal/ratelimit"
)

func (s *Server) RegisterRoutes() http.Handler {
	r := gin.Default()

	r.Use(secureHeaders())

	allowedOrigins := corsOrigins()
	r.Use(cors.New(cors.Config{
		AllowOrigins:     allowedOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: false,
		MaxAge:           12 * time.Hour,
	}))

	r.GET("/", s.HelloWorldHandler)

	r.GET("/health", s.healthHandler)

	if s.uploadsDir != "" {
		r.Static("/uploads", s.uploadsDir)
	}

	authGroup := r.Group("/api/v1/auth")
	authGroup.Use(bodyLimit(maxBodyBytes()))
	authGroup.Use(authLimiter.Middleware())
	{
		authGroup.POST("/register", s.authH.Register)
		authGroup.POST("/login", s.authH.Login)
		authGroup.POST("/refresh", s.authH.Refresh)
		authGroup.POST("/logout", s.authH.Logout)
		authGroup.POST("/password/forgot", s.authH.RequestPasswordReset)
		authGroup.POST("/password/reset", s.authH.ResetPassword)
	}

	protected := r.Group("/api/v1")
	protected.Use(bodyLimit(maxBodyBytes()))
	protected.Use(apiLimiter.Middleware())
	protected.Use(s.authMw.RequireAuth())
	{
		protected.GET("/me", s.authH.Me)
		protected.GET("/2fa/status", s.authH.Status2FA)
		protected.POST("/2fa/setup", s.authH.Setup2FA)
		protected.POST("/2fa/verify", s.authH.Verify2FA)
		protected.POST("/2fa/disable", s.authH.Disable2FA)
		protected.POST("/auth/logout-all", s.authH.LogoutAll)
		protected.GET("/sessions", s.authH.ListSessions)
		protected.POST("/sessions/:id/revoke", s.authH.RevokeSession)
		protected.POST("/me/profile-image", s.authH.UploadProfileImage)
	}

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	resp := make(map[string]string)
	resp["message"] = "Hello World"

	c.JSON(http.StatusOK, resp)
}

func (s *Server) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, s.db.Health())
}

func corsOrigins() []string {
	if raw := os.Getenv("CORS_ALLOWED_ORIGINS"); raw != "" {
		var out []string
		for _, o := range strings.Split(raw, ",") {
			if o = strings.TrimSpace(o); o != "" {
				out = append(out, o)
			}
		}
		if len(out) > 0 {
			return out
		}
	}
	return []string{"http://localhost:5173"}
}

// authLimiter is the strict per-IP budget for credential endpoints
// (register/login/refresh/password reset) — brute-force protection.
var authLimiter = ratelimit.New(authRateLimitRequests(), time.Minute)

// apiLimiter is the per-IP budget for authenticated account endpoints.
var apiLimiter = ratelimit.New(apiRateLimitRequests(), time.Minute)

// bodyLimit caps the request body size. When a client exceeds it,
// MaxBytesReader makes BindJSON fail, so oversized requests are rejected
// before they can consume unbounded memory.
func bodyLimit(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Body != nil {
			c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		}
		c.Next()
	}
}

func authRateLimitRequests() int {
	return envInt("AUTH_RATE_LIMIT_REQUESTS", 20)
}

func apiRateLimitRequests() int {
	return envInt("API_RATE_LIMIT_REQUESTS", 300)
}

func maxBodyBytes() int64 {
	if v := envInt("MAX_BODY_BYTES", 5<<20); v > 0 {
		return int64(v)
	}
	return 5 << 20
}

func envInt(key string, def int) int {
	if raw := os.Getenv(key); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			return n
		}
	}
	return def
}

func secureHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		h := c.Writer.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		if c.Request.TLS != nil {
			h.Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
		}
		c.Next()
	}
}
