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
		AllowHeaders:     []string{"Accept", "Authorization", "Content-Type"},
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
			protected.GET("/recommendations", s.handler.Recommendations)
			protected.GET("/profile", s.handler.Profile)
			protected.POST("/interactions", s.handler.RecordInteraction)
		}

		// Public catalogue reads exposed by the model service.
		api.GET("/events/:id", s.handler.GetEvent)
		api.GET("/events/:id/similar", s.handler.SimilarEvents)
	}

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Donjo ML Service API"})
}

func (s *Server) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "up", "db": s.db.Health()})
}

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
