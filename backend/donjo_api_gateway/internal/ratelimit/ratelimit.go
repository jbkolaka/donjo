package ratelimit

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// Limiter is a process-local, fixed-window rate limiter keyed by the client's
// socket IP (RemoteAddr). Acceptable for the current single-instance
// deployment; for horizontal scaling it must move to a shared store
// (e.g. Redis). Keying on the socket IP (not forwarded headers) means a
// client can't clear its bucket by spoofing X-Forwarded-For.
type Limiter struct {
	mu     sync.Mutex
	limit  int
	window time.Duration
	seen   map[string]*bucket
}

type bucket struct {
	start time.Time
	count int
}

// New returns a limiter allowing `limit` requests per `window` per client.
// `window` is rounded to whole seconds.
func New(limit int, window time.Duration) *Limiter {
	if limit <= 0 {
		limit = 1
	}
	if window <= 0 {
		window = time.Second
	}
	return &Limiter{
		limit:  limit,
		window: window,
		seen:   make(map[string]*bucket),
	}
}

// Allow reports whether a request from key fits inside the current window.
func (l *Limiter) Allow(key string) bool {
	now := time.Now()
	l.mu.Lock()
	defer l.mu.Unlock()

	b, ok := l.seen[key]
	if !ok || now.Sub(b.start) >= l.window {
		b = &bucket{start: now}
		l.seen[key] = b
	}
	b.count++
	if b.count <= l.limit {
		return true
	}
	l.prune(now)
	return false
}

// prune opportunistically drops expired buckets to bound the map's memory.
func (l *Limiter) prune(now time.Time) {
	if len(l.seen) <= 4096 {
		return
	}
	for k, v := range l.seen {
		if now.Sub(v.start) >= l.window {
			delete(l.seen, k)
		}
	}
}

// Middleware rejects over-limit clients with HTTP 429 before they reach the
// proxy.
func (l *Limiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !l.Allow(c.RemoteIP()) {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": "rate limit exceeded, try again shortly"})
			return
		}
		c.Next()
	}
}