package server

import (
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"donjo_booking/internal/ratelimit"
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

		bookings := api.Group("/bookings")
		bookings.Use(s.authMw.RequireAuth())
		{
			bookings.GET("/me", s.handle.ListMyBookings)
			bookings.GET("/:id", s.handle.BookingDetail)
		}

		instances := api.Group("/instances")
		instances.Use(s.authMw.RequireAuth())
		{
			instances.GET("/me", s.handle.ListMyInstances)
			instances.POST("/:id/assign", s.handle.AssignHolder)
			instances.POST("/:id/share", s.handle.ShareTicket)
			instances.DELETE("/:id/share", s.handle.CancelShare)
			instances.POST("/:id/resale", s.handle.ListForResale)
			instances.DELETE("/:id/resale", s.handle.UnlistResale)
			instances.POST("/:id/buy", s.handle.BuyResale)
		}
		api.POST("/instances/claim", s.authMw.RequireAuth(), s.handle.ClaimTicket)
		api.GET("/instances/marketplace", s.handle.Marketplace)

		// Public gate: presented admission codes validate with no
		// authentication. Stricter rate budget because this endpoint doubles
		// as a code oracle.
		gate := api.Group("/instances")
		gate.Use(checkinLimiter.Middleware())
		{
			gate.POST("/checkin", s.handle.Checkin)
		}

		waitlist := api.Group("/waitlist")
		waitlist.Use(s.authMw.RequireAuth())
		{
			waitlist.POST("", s.handle.JoinWaitlist)
			waitlist.DELETE("", s.handle.LeaveWaitlist)
			waitlist.GET("", s.handle.Waitlist)
		}

		scanLocations := api.Group("/scan-locations")
		scanLocations.Use(s.authMw.RequireAuth())
		{
			scanLocations.POST("", s.handle.CreateScanLocation)
			scanLocations.GET("", s.handle.ScanLocations)
		}
	}

	return r
}

func (s *Server) HelloWorldHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Donjo Booking Service API"})
}

func (s *Server) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, s.db.Health())
}

// rateLimiter is the global per-IP budget for the API.
var rateLimiter = ratelimit.New(rateLimitRequests(), time.Minute)

// checkinLimiter is the strict per-IP budget for POST /instances/checkin.
var checkinLimiter = ratelimit.New(checkinRateLimitRequests(), time.Minute)

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

func checkinRateLimitRequests() int {
	return envInt("CHECKIN_RATE_LIMIT_REQUESTS", 60)
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