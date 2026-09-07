# Project donjo_payment

Payments: every completed purchase lands as a **transaction** (money in/out),
an **escrow** (the organizer's payout held until the event completes) and a
**wallet entry** (the organizer's ledger), written together in one SQLite
transaction. It listens on RabbitMQ for `ticket.purchased` events from
`donjo_event`, records the money movement atomically, and announces the
resulting ids back on `payment.processed` so `donjo_booking` can backfill the
booking with its `transaction_id` / `escrow_id`.

## Environment variables

Required configuration:

```bash
PORT=8083
BLUEPRINT_DB_URL=./db/payment.db
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
  tables are created if missing. It is gitignored: it holds financial records
  (payments, escrow holds, wallet ledgers) and M-Pesa details.
- `RABBITMQ_URL` is the AMQP URL used by the consumer and publisher (default
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

# Request body cap in bytes (default 1 MiB).
MAX_BODY_BYTES=1048576
```

## Authentication & Authorization

Like the other services, there is **no login or user database**. All protected
endpoints require `Authorization: Bearer <access_token>` issued by
`donjo_backend`. Scoping is claim-driven:

- **Buyer scope**: `user_id` owns its transactions and the escrows linked to
  them — a foreign or nonexistent `:id` returns `404`, not `403`.
- **Organizer scope**: the wallet ledger is keyed by `creator_id` from the
  purchase event; each organizer only ever sees their own holds.

## Money flow

```
donjo_event   --ticket.purchased-->   donjo_payment (donjo.payment.sales)
                                         => INSERT transaction (paid/mpesa) + escrow (held) + wallet credit
donjo_payment --payment.processed--> donjo_booking (backfills transaction_id/escrow_id)
```

- One completed `ticket.purchased` becomes a **paid** M-Pesa transaction
  (`mpesa_express`), a **held** escrow with `release_condition =
  'event_completed'`, and a credit in the organizer's wallet ledger — committed
  in a single SQLite transaction, so the purchase either lands whole or not at
  all.
- Money math: `amount = qty * (unit_price + service_fee + processing_fee)`;
  `platform_fee = service_fee + processing_fee`; `organizer_amount
  (escrowed) = amount - platform_fee`. All money values are REAL (KES).
- The escrow is linked by the **order id** (`escrows.booking_id = order id`)
  because the payment service does not know the booking UUID yet;
  `donjo_booking` matches `payment.processed` by `order_number` and backfills
  the booking's `transaction_id` / `escrow_id`. Escrow reads are guarded by a
  join onto the buyer's transaction (`t.reference = e.booking_id`).
- **At-most-once records**: a redelivered `ticket.purchased` (broker was down,
  consumer crash) is de-duplicated — the booking side is protected by the
  UNIQUE `order_number`, the payment side by an existence check inside the
  record transaction — so retries never mint duplicate transactions or
  bookings.
- Payout/release mechanics (releasing the escrow to the organizer after the
  event, disputes, refunds) are future work; today the hold is recorded and
  reported, and the organizer's ledger reflects it.

## RabbitMQ

This service is a **consumer and publisher** on the `donjo.events` topic
exchange. It declares its **own queue** (`donjo.payment.sales`) bound to
`ticket.purchased` — no competing consumers, so it never races
`donjo_backend` or `donjo_event` over the same messages:

| Direction | Routing key       | Payload (enriched) | Effect |
|-----------|-------------------|--------------------|--------|
| consume   | `ticket.purchased` | `order_id`, `event_id`/`slug`/`title`, `ticket_id`/`type`/`name`, `quantity`, `user_id`/`user_email`, `unit_price`, `service_fee`, `processing_fee`, `amount`, `currency`, `creator_id` | Records the transaction + escrow + wallet entry atomically. |
| publish   | `payment.processed` | `order_id`, `transaction_id`/`status`, `escrow_id`/`status`/`amount`, `platform_fee`, `organizer_amount`, `payment_method`, `currency` | Consumed by `donjo_booking` to backfill the booking's payment ids. |

The consumer acks only after the transactional insert succeeds; the publish is
best-effort (the database is the source of truth). Id requires no clock
synchronization across the fleet.

## Transactions

| Method | Path                          | Auth | Body / Purpose |
|--------|-------------------------------|------|----------------|
| GET    | `/api/v1/transactions/me`     | Bearer | All of the buyer's transactions, newest first, each with its escrow joined in. |
| GET    | `/api/v1/transactions/:id`    | Bearer | One transaction (buyer scope; another user's id returns `404`). |

## Escrows & the wallet

The escrow lives beside the transaction it belongs to; the wallet is the
organizer's per-user ledger of holds (`source_type='escrow'`,
`source_id=<escrow_id>`), with a running `balance_after`.

| Method | Path               | Auth | Body / Purpose |
|--------|--------------------|------|----------------|
| GET    | `/api/v1/escrows/:id` | Bearer | One escrow (scoped through the buyer's transaction; another user's id returns `404`). |
| GET    | `/api/v1/wallet/me` | Bearer | The caller's wallet ledger (organizer); empty for anyone with no holds. |

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
- **Cross-user isolation**: transactions and escrows are owner-scoped by
  `user_id` (a foreign or nonexistent id returns `404`); escrow access is
  joined through the buyer's transaction reference, so another user's escrow
  id cannot be probed. The consumer's transaction + escrow + wallet insert
  runs inside one explicit transaction — a purchase either lands whole or not
  at all — and redelivered orders are de-duplicated.
- **Rate limiting**: per-IP fixed-window budget over the whole API (`429` on
  breach).
- **Body cap**: `http.MaxBytesReader` rejects oversized payloads (`400
  "request body too large"`) before unbounded parsing.
- **Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`;
  over TLS, `Strict-Transport-Security` is added.
- **Data at rest**: `db/` and `*.db*` are gitignored; never commit the SQLite
  file (contains payment records, M-Pesa details, and wallet ledgers).