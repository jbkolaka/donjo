# Project donjo_notifications

In-app notifications and the "for you" feed. It turns the `donjo.events`
catalog + sales stream into labelled messages: an `event.published` creates
event-discovery feed items for everyone with an active push device, and
`ticket.purchased` sends the buyer an order confirmation while alerting the
creator about the sale — themed by seeded **templates** (`{{variable}}`
placeholders rendered at send time). Like the other services it consumes
`donjo.events` on its **own** RabbitMQ queue (`donjo.notifications.sync`),
and keeps its own SQLite store (notifications, feed items, templates and
push devices). It never talks to Postgres.

The service is **consumer-only**, never publishes — but it exposes a small
HTTP surface so the mobile/web app can render notifications, mark them
read/clicked, drive feed engagement, and register push tokens, plus a
service-token button for other microservices to push a message at an
arbitrary user.

## Environment variables

Required configuration:

```bash
PORT=8086
BLUEPRINT_DB_URL=./db/notification.db
JWT_SECRET=<long-random-string>
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

- `JWT_SECRET` must be **identical to the auth backend's** (`donjo_backend`).
  This service does not issue tokens; it only validates the Bearer access
  tokens issued by `donjo_backend` (HS256, issuer `donjo`, audience
  `donjo-api`). A mismatch makes every authenticated request fail with `401`.
- `BLUEPRINT_DB_URL` points at the local SQLite database. The `db/` directory
  is created if missing and the schema (with the four seeded templates) is
  applied automatically on startup. It is gitignored: it holds user
  notifications, feed items and push device tokens.
- `RABBITMQ_URL` is the AMQP URL used by the consumer (default
  `amqp://guest:guest@localhost:5672/`). When the broker is unreachable the
  service **degrades gracefully**: it keeps serving the HTTP API, and events
  stay queued on the broker until the consumer reconnects and ingests them.
- `CORS_ALLOWED_ORIGINS` is a comma-separated allow-list (default
  `http://localhost:5173`).

Optional configuration:

```bash
# Must match the service pushing notifications for other users.
SERVICE_TOKEN=<long-random-string>

# TLS: both must be set to serve HTTPS; otherwise plain HTTP (dev).
TLS_CERT_FILE=./certs/fullchain.pem
TLS_KEY_FILE=./certs/privkey.pem

# Rate limits (per client IP, fixed 60s window).
RATE_LIMIT_REQUESTS=300          # global /api/v1 budget

# Request body cap in bytes (default 1 MiB).
MAX_BODY_BYTES=1048576
```

## Authentication

Like `donjo_event` and `donjo_payment`, this service has **no login or user
database**. Every per-user route requires `Authorization: Bearer
<access_token>` issued by `donjo_backend`; the `user_id` claim is who owns
the notification/feed/device rows, and reads/writes are **scoped to that
claim** — the payload can never name a different victim. The template
catalogue is public. Requests without a valid token get `401`.

**Service-to-service pushes**: `POST /api/v1/notifications` normally targets
the authenticated caller. When `SERVICE_TOKEN` is configured, a request
carrying the matching `X-Service-Token` header may set `user_id` to deliver
to any user (used by other microservices to ping a creator, admin, etc.).

## RabbitMQ

This service is a **consumer only** on the `donjo.events` topic exchange. It
declares its **own queue** (`donjo.notifications.sync`) bound to the ingest
keys — no competing consumers, so it never races `donjo_event`,
`donjo_backend`, or `donjo_booking`:

| Routing key        | Effect |
|--------------------|--------|
| `ticket.purchased` | Buyer: `purchase_confirmation` notification + feed item. Creator (when different from buyer): `sale_alert` notification + feed item. |
| `event.published`  | `event_discovery` notifications + feed items for every user with an active push device. |
| (any other key)    | Acked and ignored — notifications only care about sales and published events. |

Templates render at write time (e.g. `You're going to {{event_title}}! {{quantity}} x
{{ticket_name}} (order {{order_id}}).`). The consumer acks only after the
SQLite write succeeds and requeues failures with a short backoff, dropping a
message after 20 consecutive failures to avoid a hot requeue loop.

## API

| Method | Path                                   | Auth   | Purpose |
|--------|----------------------------------------|--------|---------|
| POST   | `/api/v1/notifications`                | Bearer | Create a notification (and optional feed item) for the caller. `?` set `user_id` requires a valid `X-Service-Token`. |
| GET    | `/api/v1/notifications`                | Bearer | The caller's notifications, newest first: `?status=&limit=` (max 100). |
| GET    | `/api/v1/notifications/unread-count`   | Bearer | Number of unread notifications. |
| PATCH  | `/api/v1/notifications/:id/read`       | Bearer | Mark one notification read. |
| PATCH  | `/api/v1/notifications/:id/clicked`    | Bearer | Mark one notification clicked (implies read). |
| GET    | `/api/v1/feed`                         | Bearer | The caller's feed, highest priority first: `?limit=` (max 100), `?unread=true`. |
| PATCH  | `/api/v1/feed/:id/view`                | Bearer | Mark a feed item viewed. |
| PATCH  | `/api/v1/feed/:id/click`               | Bearer | Mark a feed item opened (implies viewed). |
| PATCH  | `/api/v1/feed/:id/interact`            | Bearer | Mark a feed item interacted with (implies viewed). |
| POST   | `/api/v1/devices`                      | Bearer | Register/update a push device `{device_token, platform, device_id?, device_name?}` (upsert on user+token). |
| GET    | `/api/v1/devices/me`                   | Bearer | The caller's push devices. |
| DELETE | `/api/v1/devices/:id`                  | Bearer | Deactivate a push device. |
| GET    | `/api/v1/templates`                    | —      | Active notification templates (public catalogue). |

```bash
# the caller's notifications, newest first
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8086/api/v1/notifications?limit=20"
# mark one read
curl -X PATCH -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8086/api/v1/notifications/<id>/read"
# the feed, highest-priority first
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8086/api/v1/feed"
# register a push device so event.discovery finds you
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"device_token":"fcm-token-1","platform":"android","device_name":"pixel"}' \
  "http://localhost:8086/api/v1/devices"
# service-to-service push for an arbitrary user
curl -X POST -H "Content-Type: application/json" \
  -H "X-Service-Token: $SERVICE_TOKEN" \
  -d '{"type":"welcome","template_id":"00000000-0000-0000-0000-000000000004",
       "template_data":{"full_name":"Ada"},"user_id":"<target>"}' \
  "http://localhost:8086/api/v1/notifications"
```

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

## Security & hardening

- **No untrusted SQL**: all queries are parameterized; user values always
  travel as `?` bound arguments.
- **AuthN/AuthZ**: JWT is pinned (HS256, issuer/audience/expiry checked).
  Every per-user route is scoped to the `user_id` claim from the token — a
  cancelled update can never touch another user's notification, feed item or
  device. The only escape hatch is a configured `SERVICE_TOKEN` compared
  constant-time via the `X-Service-Token` header.
- **Reque loop protection**: consumer failures are backed off and finally
  dropped after 20 attempts, so a poison message can't pin a core.
- **Rate limiting**: per-IP fixed-window budget over the whole API (`429` on
  breach).
- **Body cap**: `http.MaxBytesReader` rejects oversized payloads (`400
  "request body too large"`) before unbounded parsing.
- **Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`;
  over TLS, `Strict-Transport-Security` is added.
- **Data at rest**: `db/` and `*.db*` are gitignored; never commit the SQLite
  file (contains notification history and push device tokens).