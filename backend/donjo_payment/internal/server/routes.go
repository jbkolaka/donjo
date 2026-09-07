package server

import (
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"donjo_payment/internal/ratelimit"
)

func (s *Server) RegisterRoutes() http.Handler {
	r := gin.Default()

	r.Use(secureHeaders())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     corsOrigins(),
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: false,
	}))

	r.GET("/", s.HelloWorldHandler)
	r.GET("/health", s.healthHandler)

	api := r.Group("/api/v1")
	{
		api.Use(bodyLimit(maxBodyBytes()))
		api.Use(rateLimiter.Middleware())

		me := api.Group("")
		me.Use(s.authMw.RequireAuth())
		{
			me.GET("/transactions/me", s.handle.ListMyTransactions)
			me.GET("/transactions/:id", s.handle.TransactionDetail)
			me.GET("/escrows/:id", s.handle.EscrowDetail)
			me.GET("/wallet/me", s.handle.MyWallet)
		}
	}

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Donjo Payment Service API"})
}

func (s *Server) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, s.db.Health())
}

// rateLimiter is the global per-IP budget for the API.
var rateLimiter = ratelimit.New(rateLimitRequests(), time.Minute)

func secureHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("Referrer-Policy", "no-referrer")
		c.Next()
	}
}

func bodyLimit(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Body != nil {
			c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		}
		c.Next()
	}
}

func rateLimitRequests() int {
	return envInt("RATE_LIMIT_REQUESTS", 300)
}

func maxBodyBytes() int64 {
	if v := envInt("MAX_BODY_BYTES", 1<<20); v > 0 {
		return int64(v)
	}
	return 1 << 20
}

func envInt(key string, def int) int {
	if raw := os.Getenv(key); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			return n
		}
	}
	return def
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
