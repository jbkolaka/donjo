package gateway

import (
	"encoding/json"
	"log"
	"net/http"
	"net/http/httputil"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
)

// RouterKey identifies which upstream (by name) owns a path.
type RouterKey string

// Rule maps a path pattern to an upstream. First match wins; Rules are
// declared most-specific-first so shared prefixes resolve to the right owner
// (e.g. /events/:id/similar is the ML service, /events/... is donjo_event).
type Rule struct {
	Pattern *regexp.Regexp
	Target  RouterKey
}

var routingRules = []Rule{
	{regexp.MustCompile(`^/api/v1/events/[^/]+/similar$`), "ml"},
	{regexp.MustCompile(`^/api/v1/events`), "event"},
	{regexp.MustCompile(`^/api/v1/venues`), "event"},

	{regexp.MustCompile(`^/api/v1/auth/`), "auth"},
	{regexp.MustCompile(`^/api/v1/me(/|$)`), "auth"},
	{regexp.MustCompile(`^/api/v1/2fa(/|$)`), "auth"},
	{regexp.MustCompile(`^/api/v1/sessions(/|$)`), "auth"},
	{regexp.MustCompile(`^/uploads/`), "auth"},

	{regexp.MustCompile(`^/api/v1/bookings(/|$)`), "booking"},
	{regexp.MustCompile(`^/api/v1/instances(/|$)`), "booking"},
	{regexp.MustCompile(`^/api/v1/waitlist(/|$)`), "booking"},
	{regexp.MustCompile(`^/api/v1/scan-locations(/|$)`), "booking"},

	{regexp.MustCompile(`^/api/v1/transactions(/|$)`), "payment"},
	{regexp.MustCompile(`^/api/v1/escrows(/|$)`), "payment"},
	{regexp.MustCompile(`^/api/v1/wallet(/|$)`), "payment"},

	{regexp.MustCompile(`^/api/v1/search(/|$)`), "search"},

	{regexp.MustCompile(`^/api/v1/recommendations(/|$)`), "ml"},
	{regexp.MustCompile(`^/api/v1/profile(/|$)`), "ml"},
	{regexp.MustCompile(`^/api/v1/interactions(/|$)`), "ml"},

	{regexp.MustCompile(`^/api/v1/notifications(/|$)`), "notifications"},
	{regexp.MustCompile(`^/api/v1/feed(/|$)`), "notifications"},
	{regexp.MustCompile(`^/api/v1/devices(/|$)`), "notifications"},
	{regexp.MustCompile(`^/api/v1/templates(/|$)`), "notifications"},
}

// Gateway routes inbound requests to the right backend microservice over an
// httputil.ReverseProxy pool. It is stateless about JWTs: authorization is
// passed through untouched and each upstream still vets its own requests.
type Gateway struct {
	log       *log.Logger
	upstreams map[RouterKey]*Upstream
	proxies   map[RouterKey]*httputil.ReverseProxy
	rules     []Rule
	health    *HealthChecker
}

// NewGateway builds the proxy pool and health checker from its config.
func NewGateway(cfg *Config) *Gateway {
	g := &Gateway{
		log:       log.New(log.Writer(), "[gateway] ", log.LstdFlags),
		upstreams: map[RouterKey]*Upstream{},
		proxies:   map[RouterKey]*httputil.ReverseProxy{},
		rules:     routingRules,
	}
	for _, up := range cfg.Upstreams {
		key := RouterKey(up.Name)
		g.upstreams[key] = up
		g.proxies[key] = newProxy(up, g)
	}
	g.health = NewHealthChecker(g, cfg.HealthTTL, cfg.RequestTimeout)
	return g
}

// ServeHTTP implements http.Handler for gin NoRoute: routes the request to
// the matching upstream or answers 404 when no upstream owns the path.
func (g *Gateway) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	target := g.targetFor(r.URL.Path)
	if target == "" {
		writeJSON(w, http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	g.logf("%s %s -> %s", r.Method, r.URL.Path, target)
	g.proxies[target].ServeHTTP(w, r)
}

// targetFor returns the upstream name owning path, or "" if none do.
func (g *Gateway) targetFor(path string) RouterKey {
	for _, rule := range g.rules {
		if rule.Pattern.MatchString(path) {
			return rule.Target
		}
	}
	return ""
}

// upstream returns an upstream by its routing key (nil if unknown).
func (g *Gateway) upstream(name RouterKey) *Upstream {
	return g.upstreams[name]
}

// Health returns the (cached) aggregate upstream health view.
func (g *Gateway) Health() HealthStatus { return g.health.Check() }

func (g *Gateway) logf(format string, args ...interface{}) {
	g.log.Printf(format, args...)
}

// newProxy wires one httputil.ReverseProxy for an upstream: it rewrites the
// destination, pins the real client IP into X-Forwarded-For (overwriting any
// spoofed value), strips upstream CORS headers so the gateway is the single
// source of CORS, and turns upstream failures into a clean 502.
func newProxy(up *Upstream, g *Gateway) *httputil.ReverseProxy {
	proxy := &httputil.ReverseProxy{
		Director: func(r *http.Request) {
			if p := r.Header.Get("X-Forwarded-For"); p != "" {
				g.logf("dropping spoofed X-Forwarded-For %q from %s", p, r.RemoteAddr)
			}
			r.URL.Scheme = up.URL.Scheme
			r.URL.Host = up.URL.Host
			proto := "http"
			if r.TLS != nil {
				proto = "https"
			}
			r.Header.Set("X-Forwarded-Host", r.Host)
			r.Header.Set("X-Forwarded-Proto", proto)
			// X-Forwarded-For is left to net/http/httputil, which sets it to
			// the socket peer exactly once. Deleting any inbound value means a
			// client can't spoof its address to the rate-limited upstreams.
			r.Header.Del("X-Forwarded-For")
		},
		ModifyResponse: func(resp *http.Response) error {
			for _, h := range []string{
				"Access-Control-Allow-Origin",
				"Access-Control-Allow-Credentials",
				"Access-Control-Allow-Headers",
				"Access-Control-Allow-Methods",
				"Access-Control-Expose-Headers",
				"Access-Control-Max-Age",
			} {
				resp.Header.Del(h)
			}
			return nil
		},
		ErrorHandler: func(w http.ResponseWriter, r *http.Request, err error) {
			g.logf("proxy %s %s -> %v", r.Method, r.URL.Path, err)
			if err != nil && strings.Contains(err.Error(), "context canceled") {
				return // client went away; nothing to write
			}
			writeJSON(w, http.StatusBadGateway, gin.H{"error": "service unavailable"})
		},
		Transport: &http.Transport{
			Proxy:                 http.ProxyFromEnvironment,
			MaxIdleConns:          100,
			IdleConnTimeout:       60e9, // 60s
			TLSHandshakeTimeout:   10e9,
			ResponseHeaderTimeout: up.ReadTimeout,
		},
	}
	return proxy
}

// clientIP extracts the host from a RemoteAddr "ip:port".
func clientIP(remoteAddr string) string {
	i := strings.LastIndexByte(remoteAddr, ':')
	if i > 0 {
		if v := remoteAddr[:i]; strings.HasPrefix(v, "[") {
			v = strings.TrimSuffix(strings.TrimPrefix(v, "["), "]") // strip ipv6 brackets
			return v
		}
		return remoteAddr[:i]
	}
	return remoteAddr
}

func writeJSON(w http.ResponseWriter, status int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}