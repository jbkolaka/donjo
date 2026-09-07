package server

import (
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func (s *Server) RegisterRoutes() http.Handler {
	r := gin.Default()

	r.Use(secureHeaders())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     corsOrigins(),
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Accept", "Authorization", "Content-Type", "X-Service-Token"},
		AllowCredentials: false,
	}))

	r.GET("/", s.HelloWorldHandler)
	r.GET("/health", s.healthHandler)

	api := r.Group("/api/v1")
	{
		api.Use(bodyLimit(maxBodyBytes()))
		api.Use(rateLimiter.Middleware())

		// Per-user routes (identity from the JWT).
		protected := api.Group("")
		protected.Use(s.handler.Auth().RequireAuth())
		{
			protected.GET("/notifications", s.handler.ListNotifications)
			protected.GET("/notifications/unread-count", s.handler.UnreadCount)
			protected.POST("/notifications", s.handler.CreateNotification)
			protected.PATCH("/notifications/:id/read", s.handler.MarkRead)
			protected.PATCH("/notifications/:id/clicked", s.handler.MarkClicked)

			protected.GET("/feed", s.handler.GetFeed)
			protected.PATCH("/feed/:id/view", s.handler.MarkFeedViewed)
			protected.PATCH("/feed/:id/click", s.handler.MarkFeedClicked)
			protected.PATCH("/feed/:id/interact", s.handler.MarkFeedInteracted)

			protected.POST("/devices", s.handler.RegisterDevice)
			protected.GET("/devices/me", s.handler.ListDevices)
			protected.DELETE("/devices/:id", s.handler.DeleteDevice)
		}

		// Public reads.
		api.GET("/templates", s.handler.ListTemplates)
	}

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Donjo Notification Service API"})
}

func (s *Server) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "up", "db": s.db.Health()})
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

func bodyLimit(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Body != nil {
			c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		}
		c.Next()
	}
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