package gateway

import (
	"context"
	"io"
	"net/http"
	"sync"
	"time"
)

// HealthChecker probes each upstream's /health endpoint and caches the last
// result so repeated admin requests don't hammer the pool.
type HealthChecker struct {
	gw       *Gateway
	ttl      time.Duration
	timeout  time.Duration
	mu       sync.Mutex
	cached   map[RouterKey]string
	cachedAt time.Time
}

// HealthStatus is the gateway's aggregate view of its upstreams.
type HealthStatus struct {
	Status   string            `json:"status"`
	Services map[string]string `json:"services"`
	Checked  time.Time         `json:"checked_at"`
}

func NewHealthChecker(gw *Gateway, ttl, timeout time.Duration) *HealthChecker {
	return &HealthChecker{
		gw:      gw,
		ttl:     ttl,
		timeout: timeout,
		cached:  map[RouterKey]string{},
	}
}

// Check returns the cached health view, re-probing any upstream whose result
// is stale.
func (h *HealthChecker) Check() HealthStatus {
	h.mu.Lock()
	if h.ttl > 0 && !h.cachedAt.IsZero() && time.Since(h.cachedAt) < h.ttl {
		out := h.snapshotLocked()
		h.mu.Unlock()
		return out
	}
	h.mu.Unlock()

	statuses := h.probeAll()
	h.mu.Lock()
	h.cached = statuses
	h.cachedAt = time.Now()
	out := h.snapshotLocked()
	h.mu.Unlock()
	return out
}

func (h *HealthChecker) snapshotLocked() HealthStatus {
	status := "up"
	for _, s := range h.cached {
		if s != "up" {
			status = "degraded"
			break
		}
	}
	services := make(map[string]string, len(h.cached))
	for k, v := range h.cached {
		services[string(k)] = v
	}
	return HealthStatus{Status: status, Services: services, Checked: h.cachedAt}
}

func (h *HealthChecker) probeAll() map[RouterKey]string {
	out := make(map[RouterKey]string, len(h.gw.upstreams))
	for name, up := range h.gw.upstreams {
		out[name] = probe(up, h.timeout)
	}
	return out
}

// probe asks one upstream whether it is alive. Any HTTP response is "up" —
// the exact health JSON shape differs per service.
func probe(up *Upstream, timeout time.Duration) string {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, up.URL.String()+"/health", nil)
	if err != nil {
		return "down"
	}
	client := &http.Client{
		Transport: &http.Transport{
			Proxy:                 http.ProxyFromEnvironment,
			IdleConnTimeout:       30 * time.Second,
			ResponseHeaderTimeout: timeout,
		},
	}
	resp, err := client.Do(req)
	if err != nil {
		return "down"
	}
	defer func() {
		_, _ = io.Copy(io.Discard, resp.Body)
		resp.Body.Close()
	}()
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return "up"
	}
	return "down"
}