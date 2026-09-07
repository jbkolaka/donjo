package server

import (
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func (s *Server) RegisterRoutes() http.Handler {
	r := gin.Default()

	r.Use(secureHeaders())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     s.config.CORSOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Accept", "Authorization", "Content-Type", "X-Service-Token"},
		AllowCredentials: false,
		MaxAge:           12 * time.Hour,
	}))

	r.GET("/", s.HelloWorldHandler)
	r.GET("/health", s.healthHandler)

	// Every other path is a proxied API call: shared body cap plus a coarse
	// per-socket-IP rate budget, then handed to the gateway for routing. CORS
	// preflights are already answered by the middleware above.
	r.Use(bodyLimit(s.config.MaxBodyBytes))
	r.Use(rateLimiter.Middleware())
	r.NoRoute(func(c *gin.Context) {
		s.gateway.ServeHTTP(c.Writer, c.Request)
	})

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Donjo API Gateway"})
}

// healthHandler reports the gateway's readiness plus, under "services", the
// aggregated (cached) health of every upstream microservice. While any
// upstream is down the response is 503 (not ready to route traffic).
func (s *Server) healthHandler(c *gin.Context) {
	state := s.gateway.Health()

	status := http.StatusOK
	if state.Status != "up" {
		status = http.StatusServiceUnavailable
	}
	c.JSON(status, gin.H{
		"status":     state.Status,
		"checked_at": state.Checked,
		"services":   state.Services,
	})
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