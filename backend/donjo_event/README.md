# Project donjo_event

One Paragraph of project description goes here

## Environment variables

Required configuration:

```bash
PORT=8081
BLUEPRINT_DB_URL=./db/test.db
JWT_SECRET=<long-random-string>
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

- `JWT_SECRET` must be **identical to the auth backend's** (`donjo_backend`).
  This service does not issue tokens; it only validates the Bearer access
  tokens issued by `donjo_backend` (HS256, issuer `donjo`, audience
  `donjo-api`). A mismatch makes every authenticated request fail with `401`.
- `BLUEPRINT_DB_URL` points at the local SQLite database. The `db/` directory
  must exist — the schema is created automatically on startup; the file and
  tables are created if missing. It is gitignored: it holds event/PII data and
  ticket-code hashes.
- `RABBITMQ_URL` is the AMQP URL used to publish event messages (default
  `amqp://guest:guest@localhost:5672/`). When the broker is unreachable the
  service **degrades gracefully**: it keeps serving HTTP and simply skips the
  publishes until the connection is back.
- `CORS_ALLOWED_ORIGINS` is a comma-separated allow-list (default
  `http://localhost:5173`).

Optional hardening configuration:

```bash
# TLS: both must be set to serve HTTPS; otherwise plain HTTP (dev).
TLS_CERT_FILE=./certs/fullchain.pem
TLS_KEY_FILE=./certs/privkey.pem

# Rate limits (per client IP, fixed 60s window).
RATE_LIMIT_REQUESTS=300          # global /api/v1 budget

# Request body cap in bytes (default 1 MiB).
MAX_BODY_BYTES=1048576
```

## Authentication & Authorization

Unlike `donjo_backend`, this service has **no login or user database**. All
protected endpoints require `Authorization: Bearer <access_token>` where the
token was issued by `donjo_backend`. The `user_id` claim is used for two
things:

- Ownership: an event or venue can only be updated/deleted, and tickets only
  created, by the creator. A foreign token gets `403`.
- Attribution: event and venue creation carry `creator_id`, and purchases
  carry the buyer `user_id` + `creator_id` into the published messages (see
  RabbitMQ below).

## Events

| Method | Path                | Auth | Body / Purpose |
|--------|---------------------|------|----------------|
| POST   | `/api/v1/events`    | Bearer | Create an event (title, category, total_capacity, start_time, end_time, optional venue_id, ...). The creator becomes `creator_id`. |
| GET    | `/api/v1/events`    | —    | List events. Public browsing returns only **active/published** events; a creator can see their own drafts by passing their `creator_id` (or a `status`). |
| GET    | `/api/v1/events/:id` | —   | Get one event with live `tickets_sold`, `revenue`, `available_tickets`. |
| GET    | `/api/v1/events/slug/:slug` | — | Look up an event by its unique slug. |
| PUT    | `/api/v1/events/:id` | Bearer | Update (owner only). |
| DELETE | `/api/v1/events/:id` | Bearer | Soft-delete (owner only). Emits `event.deleted`. |
| POST   | `/api/v1/events/:id/publish` | Bearer | Move a draft to `status=active`, `is_published=true` (owner only). |
| POST   | `/api/v1/events/:id/unpublish` | Bearer | Unpublish (owner only). |
| POST   | `/api/v1/events/:id/like` | —   | Increment the public like counter. |
| GET    | `/api/v1/events/:id/tickets` | — | List the event's ticket types. |

> Events have a unique `slug` derived from the title; a duplicate (even a
> soft-deleted one) is rejected with `409` rather than a `500`.

## Venues

| Method | Path                | Auth | Body / Purpose |
|--------|---------------------|------|----------------|
| POST   | `/api/v1/venues`    | Bearer | Create a venue. Requires `name`, `address`, `venue_type` and `capacity > 0`; `base_price` defaults to `0` if omitted. |
| GET    | `/api/v1/venues`    | —    | List venues. |
| GET    | `/api/v1/venues/:id` | —   | Get one venue. |
| PUT    | `/api/v1/venues/:id` | Bearer | Update (owner only). |
| DELETE | `/api/v1/venues/:id` | Bearer | Soft-delete (owner only). Emits `venue.deleted`. |

## Tickets & Purchase

| Method | Path                | Auth | Body / Purpose |
|--------|---------------------|------|----------------|
| POST   | `/api/v1/events/:id/tickets` | Bearer | Add a ticket type to an event (owner only). Requires `type`, `name`, non-negative `price` and `quantity > 0`; `max_per_user`/`min_per_user` default to `10`/`1`. |
| PUT    | `/api/v1/events/:id/tickets/:ticket_id` | Bearer | Update a ticket type (owner only). |
| DELETE | `/api/v1/events/:id/tickets/:ticket_id` | Bearer | Delete a ticket type (owner only); a type that has sales cannot be deleted. |
| POST   | `/api/v1/events/:id/tickets/:ticket_id/purchase` | Bearer | Buy `{quantity}` tickets. |

Purchase is atomic and guarded against overselling:

1. **Reserve** — `quantity <= total - sold - reserved` is checked in a single
   SQL statement, so concurrent purchases cannot oversell; reserved seats are
   held for the checkout window.
2. **Confirm** — the reservation is converted to a sale, and the event's
   `tickets_sold` / `revenue` are updated.
3. **Notify** — a `ticket.purchased` message is published with the buyer
   `user_id`, `creator_id`, `quantity`, all-in `amount` and the enriched order
   fields (`order_id`, event/ticket metadata, per-unit and fee breakdown,
   currency). `donjo_booking` consumes it to mint the tickets; `donjo_backend`
   consumes it for buyer/creator stats.

A failed or abandoned reservation is eventually released back to availability
(via `ticket.sale.released`). Hitting the per-user cap or running out of
inventory returns `409`.

## RabbitMQ

This service is a **publisher** on the `donjo.events` topic exchange. The auth
backend (`donjo_backend`) consumes the same exchange to keep user statistics
in sync:

| Routing key            | Payload                          | Auth effect                    |
|------------------------|----------------------------------|--------------------------------|
| `ticket.purchased`     | buyer, creator, quantity, amount, unit/fee breakdown, order + event/ticket metadata | buyer `tickets_sold`/`total_spent`; creator `total_earned`/`wallet_balance`; `donjo_booking` mints the seats |
| `event.created`        | event (creator_id)               | creator `events_created` +1    |
| `event.deleted`        | event (creator_id)               | creator `events_created` -1    |
| `venue.created`        | venue (creator_id)               | creator `venues_listed` +1     |
| `venue.deleted`        | venue (creator_id)               | creator `venues_listed` -1     |
| `event.updated` / `event.published` | event | informational                 |

It also consumes `donjo.ticket.sales` / `donjo.auth.sync` for its own needs
(releasing expired reservations) — see `internal/messaging`.

> The broker is optional at runtime: publishing is skipped while disconnected
> and consumers restart automatically on reconnect. Run one with
> `make docker-run` (RabbitMQ via Docker Compose) for the full behavior.

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

Live reload the application:
```bash
make watch
```

Run the test suite:
```bash
make test
```

Start the RabbitMQ container and the service (Docker Compose):
```bash
make docker-run
```

Stop the container:
```bash
make docker-down
```

Clean up binary from the last build:
```bash
make clean
```

## Security & hardening

- **SQL injection**: all queries are parameterized. The two filter queries
  built with `fmt.Sprintf` interpolate only hardcoded condition fragments;
  user values always travel as `?` bound args.
- **AuthN/AuthZ**: JWT is pinned (HS256, issuer/audience/expiry checked). Every
  mutation keyed on ownership uses the `user_id` claim from the token, never
  client-supplied fields, and cross-user access returns `403`.
- **Rate limiting**: per-IP fixed-window budget covers the whole API (`429` on
  breach); gate check-in rate limiting now lives in `donjo_booking`.
- **Body cap**: `http.MaxBytesReader` rejects oversized payloads (`400
  "request body too large"`) before unbounded parsing.
- **Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`.
- **TLS**: set `TLS_CERT_FILE`/`TLS_KEY_FILE` to serve HTTPS (HSTS is set by
  the auth backend automatically when serving over TLS).
- **Data at rest**: `db/` and `*.db*` are gitignored; never commit the SQLite
  file (contains emails, purchase history, and ticket-code hashes).