package gateway

import (
	"log"
	"net/url"
	"os"
	"strconv"
	"time"
)

// Upstream is a single backend microservice the gateway proxies to.
type Upstream struct {
	// Name is the routing key used in rules and health reports.
	Name string
	// URL is the base address of the service (scheme://host[:port]).
	URL *url.URL
	// ReadTimeout bounds a single proxied request's total handling time.
	ReadTimeout time.Duration
}

// Config is the gateway's runtime configuration, loadable from the
// environment with defaults matching the local compose ports.
type Config struct {
	Port           int
	Upstreams      []*Upstream
	CORSOrigins    []string
	RateLimit      int
	MaxBodyBytes   int64
	HealthTTL      time.Duration
	RequestTimeout time.Duration
}

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envInt(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			return n
		}
	}
	return def
}

func parseUpstream(name, raw string) *Upstream {
	u, err := url.Parse(raw)
	if err != nil || u.Scheme == "" || u.Host == "" {
		log.Fatalf("[gateway] invalid %s upstream URL %q", name, raw)
	}
	return &Upstream{Name: name, URL: u, ReadTimeout: 60 * time.Second}
}

// LoadConfig reads the gateway configuration from the environment.
func LoadConfig() *Config {
	cfg := &Config{
		Port:           envInt("PORT", 8087),
		RateLimit:      envInt("RATE_LIMIT_REQUESTS", 1000),
		MaxBodyBytes:   int64(envInt("MAX_BODY_BYTES", 20<<20)),
		HealthTTL:      time.Duration(envInt("HEALTH_TTL_SECONDS", 5)) * time.Second,
		RequestTimeout: 30 * time.Second,
	}

	cfg.Upstreams = []*Upstream{
		parseUpstream("auth", env("AUTH_SERVICE_URL", "http://localhost:8080")),
		parseUpstream("event", env("EVENT_SERVICE_URL", "http://localhost:8081")),
		parseUpstream("booking", env("BOOKING_SERVICE_URL", "http://localhost:8082")),
		parseUpstream("payment", env("PAYMENT_SERVICE_URL", "http://localhost:8083")),
		parseUpstream("search", env("SEARCH_SERVICE_URL", "http://localhost:8084")),
		parseUpstream("ml", env("ML_SERVICE_URL", "http://localhost:8085")),
		parseUpstream("notifications", env("NOTIFICATIONS_SERVICE_URL", "http://localhost:8086")),
	}

	origin := env("CORS_ALLOWED_ORIGINS", "http://localhost:5173")
	cfg.CORSOrigins = splitCSV(origin)

	return cfg
}

func splitCSV(raw string) []string {
	var out []string
	start := 0
	for i := 0; i <= len(raw); i++ {
		if i == len(raw) || raw[i] == ',' {
			if v := trimSpace(raw[start:i]); v != "" {
				out = append(out, v)
			}
			start = i + 1
		}
	}
	return out
}

func trimSpace(s string) string {
	i, j := 0, len(s)
	for i < j && (s[i] == ' ' || s[i] == '\t') {
		i++
	}
	for j > i && (s[j-1] == ' ' || s[j-1] == '\t') {
		j--
	}
	return s[i:j]
}