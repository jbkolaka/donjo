# Project donjo_api_gateway

The single HTTP entry point for the Donjo microservice fleet. It is a
**stateless reverse proxy**: a request arrives, a path-matching rule picks
which of the seven backend services owns the route, and the request is
forwarded over an `httputil.ReverseProxy` pool with the original path,
headers and body intact. It holds no database, no JWT secret and no business
logic — each upstream still authenticates, rate-limits and enforces its own
rules, so the gateway adds a single entry URL, a single CORS policy, a coarse
load wall and an aggregated health check without becoming a security
bottleneck itself.

```
          ┌──────────────── donjo_api_gateway (:8087) ───────────────┐
client ──▶│  path rule ─▶ reverse proxy pool ─▶ /health aggregate      │
          └──┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┘
             │      │      │      │      │      │      │      │
            auth  event booking payment search   ml  notif  uploads
           :8080   :8081   :8082  :8083  :8084  :8085  :8086 (auth/static)
```

## Routing table

First match wins; rules are declared most-specific-first so shared prefixes
resolve to the right owner (`/events/:id/similar` is the ML service while
`/events/...` is donjo_event).

| Path prefix                       | Upstream          | Port |
|-----------------------------------|-------------------|------|
| `/api/v1/auth/*`, `/api/v1/me`    | donjo_backend     | 8080 |
| `/api/v1/2fa/*`, `/api/v1/sessions/*` | donjo_backend  | 8080 |
| `/uploads/*`                      | donjo_backend     | 8080 |
| `/api/v1/events/*`, `/api/v1/venues/*` | donjo_event  | 8081 |
| `/api/v1/events/:id/similar`      | donjo_ml          | 8085 |
| `/api/v1/bookings/*`, `/api/v1/instances/*`, `/api/v1/waitlist/*`, `/api/v1/scan-locations/*` | donjo_booking | 8082 |
| `/api/v1/transactions/*`, `/api/v1/escrows/*`, `/api/v1/wallet/*` | donjo_payment | 8083 |
| `/api/v1/search/*`                | donjo_search      | 8084 |
| `/api/v1/recommendations/*`, `/api/v1/profile/*`, `/api/v1/interactions/*` | donjo_ml | 8085 |
| `/api/v1/notifications/*`, `/api/v1/feed/*`, `/api/v1/devices/*`, `/api/v1/templates/*` | donjo_notifications | 8086 |
| anything else                     | — 404             | —    |

## Environment variables

Required configuration (defaults match the local compose ports):

```bash
PORT=8087
AUTH_SERVICE_URL=http://localhost:8080
EVENT_SERVICE_URL=http://localhost:8081
BOOKING_SERVICE_URL=http://localhost:8082
PAYMENT_SERVICE_URL=http://localhost:8083
SEARCH_SERVICE_URL=http://localhost:8084
ML_SERVICE_URL=http://localhost:8085
NOTIFICATIONS_SERVICE_URL=http://localhost:8086
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

- Each `*_SERVICE_URL` is the base address of one upstream. In development
  every service runs on a host port; when the fleet shares a compose network,
  point these at the compose service names (e.g. `http://donjo_backend:8080`).
- `CORS_ALLOWED_ORIGINS` is a comma-separated allow-list (default
  `http://localhost:5173`). The gateway is the **single CORS source**: it
  answers preflights and strips upstream `Access-Control-*` headers from
  proxied responses so policies can't drift between services.

Optional hardening configuration:

```bash
# TLS: both must be set to serve HTTPS; otherwise plain HTTP (dev).
TLS_CERT_FILE=./certs/fullchain.pem
TLS_KEY_FILE=./certs/privkey.pem

# Coarse per-client-IP budget over the whole API (upstreams enforce their own
# stricter limits on top). Fixed 60s window.
RATE_LIMIT_REQUESTS=1000

# Request body cap in bytes (default 20 MiB; the profile upload max is 5 MiB).
MAX_BODY_BYTES=20971520

# How long an upstream /health result is cached (default 5s).
HEALTH_TTL_SECONDS=5
```

## Auth & identity

The gateway never inspects tokens. `Authorization: Bearer <token>`, the
`X-Service-Token` header, cookies, query strings and bodies pass through
untouched, and **each upstream vets them exactly as if the client had come
straight in**. That keeps the proxy simple and means a compromise of the
gateway alone cannot mint or validate credentials.

## Forwarding semantics

- **Identity + headers**: `Authorization`, `Content-Type`, `User-Agent`,
  `X-Service-Token` and every other request header are copied through
  unchanged, so upstream rate limiting, device logging and cross-service
  pushes still work.
- **Real client IP**: the gateway pins `X-Forwarded-For` to the actual socket
  peer and **deletes any value the client sent**, then lets the standard
  library emit it exactly once. A caller cannot spoof its address to the
  upstream rate limiters or the identity service's device records.
- **Path & query**: the `/api/v1/...` prefix is preserved (each upstream
  serves under it) and query strings are forwarded as-is. Nothing is
  rewritten except the destination host.
- **CORS**: handled once, at the gateway; upstream `Access-Control-*` headers
  are stripped from proxied responses.
- **Failures**: an unreachable upstream becomes `502 {"error":"service
  unavailable"}` — a client never sees the internal error string. Unknown
  paths get `404` from the gateway itself.

## Health

`GET /health` returns the gateway's own liveness plus the aggregated,
cache-backed status of every upstream:

```json
{
  "status": "degraded",
  "checked_at": "2026-09-07T08:00:00Z",
  "services": {
    "auth": "up", "event": "up", "booking": "up", "payment": "up",
    "search": "up", "ml": "up", "notifications": "down"
  }
}
```

Each `services` entry is a lightweight `GET <url>/health` probe with a short
timeout, cached for `HEALTH_TTL_SECONDS`. While any upstream is down the
gateway answers `503` so an orchestrator won't route traffic to a partially
dead fleet.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## MakeFile

Run build make command with tests
```bash
make all
```

Build the application
```bash
make build
```

Run the application
```bash
make run
```

Create DB container
```bash
make docker-run
```

Shutdown DB Container
```bash
make docker-down
```

DB Integrations Test:
```bash
make itest
```

Live reload the application:
```bash
make watch
```

Run the test suite:
```bash
make test
```

Clean up binary from the last build:
```bash
make clean
```

## Security notes

- **No sensitive data**: the gateway holds no secrets, no tokens, no user
  data; it forwards, it does not read.
- **Spoof-proof rate limiting**: the gateway's own budget keys on the socket
  IP (`RemoteAddr`), not on spoofable forwarded headers.
- **Bounded bodies**: `http.MaxBytesReader` caps request bodies before the
  proxy streams them upstream.
- **Header hygiene**: `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Permissions-Policy`, `Content-Security-Policy`, and —
  over TLS — `Strict-Transport-Security` are set on every response.
- **No upstream error leakage**: proxy failures are surfaced as a terse
  `502`; internal error strings stay in the gateway log.