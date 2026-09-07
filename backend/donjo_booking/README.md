# Project donjo_booking

Bookings, ticket instances, group-holder assignment, share/claim, resale and
gate check-in. This service owns what happens **after** a purchase: it listens
on RabbitMQ for `ticket.purchased` events from `donjo_event`, mints one ticket
instance per seat, and exposes the REST API that the gate scanners, group
leads and resale buyers talk to.

## Environment variables

Required configuration:

```bash
PORT=8082
BLUEPRINT_DB_URL=./db/booking.db
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
  tables are created if missing. It is gitignored: it holds PII (attendee
  names, claim e-mails, booking IPs) and the gate ticket codes.
- `RABBITMQ_URL` is the AMQP URL used by the consumer (default
  `amqp://guest:guest@localhost:5672/`). When the broker is unreachable the
  service **degrades gracefully**: it keeps serving HTTP, and purchases made
  meanwhile stay queued on the broker and are processed when the connection is
  back.
- `CORS_ALLOWED_ORIGINS` is a comma-separated allow-list (default
  `http://localhost:5173`).

Optional hardening configuration:

```bash
# TLS: both must be set to serve HTTPS; otherwise plain HTTP (dev).
TLS_CERT_FILE=./certs/fullchain.pem
TLS_KEY_FILE=./certs/privkey.pem

# Rate limits (per client IP, fixed 60s window).
RATE_LIMIT_REQUESTS=300          # global /api/v1 budget
CHECKIN_RATE_LIMIT_REQUESTS=60   # strict budget for POST /instances/checkin

# Request body cap in bytes (default 1 MiB).
MAX_BODY_BYTES=1048576
```

## Authentication & Authorization

Like `donjo_event`, this service has **no login or user database**. All
protected endpoints require `Authorization: Bearer <access_token>` where the
token was issued by `donjo_backend`. The `user_id` claim owns everything:

- **Buyer scope**: your own bookings and instances, and only yours — a foreign
  or nonexistent `:id` returns `404`, not `403`, so routes cannot be probed.
- **Group holder**: instances are transferable to a named holder who may not
  be the buyer (see below).

The exception is the **gate**: `POST /instances/checkin` and
`GET /instances/marketplace` are public, because scanners and browsers hit
them without a user session.

## RabbitMQ

This service is a **consumer** on the `donjo.events` topic exchange. It
declares its **own queue** (`donjo.booking.sales`) bound to `ticket.purchased`
— no competing consumers, so it never races `donjo_backend` or `donjo_event`
over the same messages:

| Routing key     | Payload (enriched)        | Effect |
|-----------------|---------------------------|--------|
| `ticket.purchased` | `order_id`, `event_id`/`slug`/`title`, `ticket_id`/`type`/`name`, `quantity`, `user_id`/`user_email`, `unit_price`, `service_fee`, `processing_fee`, `amount`, `currency`, `creator_id` | Creates one **booking** row + **N ticket instances** atomically (reference `DONJO-<6>` + order `DONJO-ORD-<12>`), each with a fresh 128-bit random ticket code. |

The consumer acks only after the transactional insert succeeds; a broker that
was down at publish time redelivers the message, so a purchase made while this
service was offline is still booked once the connection returns.

## Bookings

| Method | Path            | Auth | Body / Purpose |
|--------|-----------------|------|----------------|
| GET    | `/api/v1/bookings/me` | Bearer | All bookings for the buyer, each with event/ticket context and its ticket instances. |
| GET    | `/api/v1/bookings/:id` | Bearer | One booking (buyer scope; another user's id returns `404`). |

## Ticket instances (the "passes")

Each purchased seat is a `ticket_instance` with a `status` of `active`,
`pending_claim`, `listed`, `resold`, `used` or `void`. The `ticket_code` — the
value the gate scans — is random and **rotates on every change of hands**, so
a code you shared or resold can never be used by you again.

| Method | Path                    | Auth | Body / Purpose |
|--------|-------------------------|------|----------------|
| GET    | `/api/v1/instances/me`  | Bearer | Buyer/holder view of every instance, with event + ticket metadata. |
| POST   | `/api/v1/instances/:id/assign` | Bearer | Attach a group holder (`holder_name`, `holder_email`, `holder_phone`) to the instance. The holder does not need an account; check-in looks at the holder fields. |
| POST   | `/api/v1/instances/:id/share` | Bearer | Rotate the code and place the instance into `pending_claim`, returning a one-time `transfer_code` to send to the recipient. |
| DELETE | `/api/v1/instances/:id/share` | Bearer | Cancel an outstanding share and take the instance back. |
| POST   | `/api/v1/instances/claim` | Bearer | Claim a shared instance: `{email}` + `?code=<transfer_code>`. The e-mail must match the `holder_email` set by the sharer. On success the instance moves to the claimant, its holder fields are set, and the code is rotated again. |
| POST   | `/api/v1/instances/:id/resale` | Bearer | List an instance on the marketplace for `{price}`; the code is rotated and status becomes `listed`. |
| DELETE | `/api/v1/instances/:id/resale` | Bearer | Unlist it. |
| POST   | `/api/v1/instances/:id/buy` | Bearer | Buy a listed instance from another user. The seller's instance becomes `resold`; the buyer gets a brand-new instance (code rotated, `resold_price`/`resold_at` recorded). Buying your own listing returns `403`. |
| GET    | `/api/v1/instances/marketplace` | — | All `listed` instances, public. |

## Check-in (the gate)

| Method | Path                    | Auth | Body / Purpose |
|--------|-------------------------|------|----------------|
| POST   | `/api/v1/instances/checkin` | — | `{code}` → `{"allowed": true}` and the instance is marked `used`. A code that is already marked used or unknown is rejected with `422` "invalid ticket". Every scan is appended to `qr_scan_logs` with the scanner's IP and `scan_location_id` if given. |

The endpoint is **public** and rate-limited (`CHECKIN_RATE_LIMIT_REQUESTS`)
because scanners have no user session. Schema niceties: every instance carries
a UNIQUE, indexed `check_in_code` for fast gate lookups, and the waitlist's
`UNIQUE(event_id, user_id)` keeps an attendee from double-joining an event.

## Waitlist & scan locations

| Method | Path                 | Auth | Body / Purpose |
|--------|----------------------|------|----------------|
| POST   | `/api/v1/waitlist`   | Bearer | `{event_id}` — join the waitlist (upsert; re-joining moves you to the front). |
| DELETE | `/api/v1/waitlist`   | Bearer | `{event_id}` — leave. |
| GET    | `/api/v1/waitlist`   | Bearer | Your waitlist positions. |
| POST   | `/api/v1/scan-locations` | Bearer | Create a named gate/location (`name`, `radius_meters`, `is_active`). |
| GET    | `/api/v1/scan-locations` | — | List the gate locations for scanners. |

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

Run the test suite:
```bash
make test
```

Clean up binary from the last build:
```bash
make clean
```

## Security & hardening

- **SQL injection**: all queries are parameterized; user values always travel
  as `?` bound arguments.
- **Cross-user isolation**: reads are owner-scoped by `user_id` (a foreign or
  nonexistent instance id returns `404`). Every state transition is a single
  guarded `UPDATE ... WHERE id = ? AND status = ?` whose affected-row count
  must be exactly one — a lost race returns `409`, so two users can never
  claim the same share or buy the same resale. The consumer's booking +
  instances insert runs inside one explicit transaction, so a purchase either
  lands whole or not at all.
- **Code rotation**: `ticket_code` (and the one-time `transfer_code`) rotate
  on every share/claim/resale/buy and on cancel — a value seen before is never
  accepted again.
- **Generic gate errors**: every failed checkin returns the identical `422`
  response, so the endpoint cannot enumerate live vs. dead codes.
- **Rate limiting**: per-IP fixed-window budgets cover the whole API and a
  stricter budget guards the public checkin oracle (`429` on breach).
- **Body cap**: `http.MaxBytesReader` rejects oversized payloads (`400
  "request body too large"`) before unbounded parsing.
- **Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`;
  over TLS, `Strict-Transport-Security` is added.
- **Data at rest**: `db/` and `*.db*` are gitignored; never commit the SQLite
  file (contains attendee names, claim e-mails, booking IPs, and ticket
  codes).