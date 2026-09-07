package server

import (
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"donjo_event/internal/ratelimit"
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
		// Request hardening: cap body size and apply a global per-IP rate
		// budget before any handler runs. The checkin endpoint (a code-validity
		// oracle) gets a much stricter budget below.
		api.Use(bodyLimit(maxBodyBytes()))
		api.Use(rateLimiter.Middleware())

		events := api.Group("/events")
		public := events.Group("")
		public.GET("", s.eventH.ListEvents)
		public.GET("/slug/:slug", s.eventH.GetEventBySlug)
		public.GET("/:id", s.eventH.GetEvent)
		public.GET("/:id/tickets", s.eventH.ListTickets)
		public.POST("/:id/like", s.eventH.LikeEvent)

		protected := events.Group("")
		protected.Use(s.authMw.RequireAuth())
		{
			protected.POST("", s.eventH.CreateEvent)
			protected.PUT("/:id", s.eventH.UpdateEvent)
			protected.DELETE("/:id", s.eventH.DeleteEvent)
			protected.POST("/:id/publish", s.eventH.PublishEvent)
			protected.POST("/:id/unpublish", s.eventH.UnpublishEvent)
			protected.POST("/:id/tickets", s.eventH.CreateTicket)
			protected.PUT("/:id/tickets/:ticket_id", s.eventH.UpdateTicket)
			protected.DELETE("/:id/tickets/:ticket_id", s.eventH.DeleteTicket)
			protected.POST("/:id/tickets/:ticket_id/purchase", s.eventH.PurchaseTicket)
		}
	}

	venues := api.Group("/venues")
	{
		venues.GET("", s.eventH.ListVenues)
		venues.GET("/:id", s.eventH.GetVenue)

		protected := venues.Group("")
		protected.Use(s.authMw.RequireAuth())
		{
			protected.POST("", s.eventH.CreateVenue)
			protected.PUT("/:id", s.eventH.UpdateVenue)
			protected.DELETE("/:id", s.eventH.DeleteVenue)
		}
	}

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Donjo Event Service API"})
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
