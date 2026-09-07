# Project donjo_ml

Recommendations: learns each attendee's preferences from their behaviour and
serves a personalised, Reason-string explanations included. It consumes the
same `donjo.events` catalog and sales stream the other services do, on its
**own** RabbitMQ queue (`donjo.ml.sync`), and maintains two learned
artefacts in SQLite — **event embeddings** and **user embeddings** — in a
shared fixed-dimension vector space. Content vectors are built by feature
hashing (category, venue, city, price band, time-of-day/weekend, title,
organizer, ticket names), so events and users map to the same 128-dim space
with no shared dictionary and no Postgres/pgvector — the model is pure Go.

Every ingest is a retrain: a new event gets an embedding the moment
`event.created` lands, a buyer's profile is reinforced on `ticket.purchased`,
and recommendations are computed live from those vectors (cosine similarity),
cached per user + feed type, and each query is logged to `ai_queries`.

## Environment variables

Required configuration:

```bash
PORT=8085
BLUEPRINT_DB_URL=./db/ml.db
JWT_SECRET=<long-random-string>
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

- `JWT_SECRET` must be **identical to the auth backend's** (`donjo_backend`).
  This service does not issue tokens; it only validates the Bearer access
  tokens issued by `donjo_backend` (HS256, issuer `donjo`, audience
  `donjo-api`). A mismatch makes every authenticated request fail with `401`.
- `BLUEPRINT_DB_URL` points at the local SQLite model database. The `db/`
  directory is created if missing and the schema is applied automatically on
  startup. It is gitignored: it holds user profiles (learned preference
  vectors) and the query log.
- `RABBITMQ_URL` is the AMQP URL used by the consumer (default
  `amqp://guest:guest@localhost:5672/`). When the broker is unreachable the
  service **degrades gracefully**: it keeps serving the HTTP API (cold-start
  recommendations from whatever catalogue is already stored), and catalog
  events stay queued on the broker until the consumer reconnects and retrains.
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

## Authentication

Like `donjo_event` and `donjo_payment`, this service has **no login or user
database**. New-user and per-user routes require `Authorization: Bearer
<access_token>` issued by `donjo_backend`; the `user_id` claim is the identity
the model learns about. The catalogue reads (`/events/:id`,
`/events/:id/similar`) are public. Requests without a valid token get `401`;
the profile/interaction/recommendation routes are scoped to the token's
`user_id`, never to client-supplied fields.

## How the model works

```
donjo_event --event.created/updated------>  event embedding (128-dim, feature-hashed)
           --ticket.type.created/updated->  re-vectorise the parent event
           --venue.created/updated------->  venue doc (feature-augments its events)
           --ticket.purchased------------>  reinforce buyer + bump event popularity

user behaviour --POST /interactions------>  weighted event vector sum -> user embedding
```

- **Feature space**: `EmbeddingDim = 128`. Each attribute hashes to an index
  under a stable FNV-1a hash whose high bit picks the sign, so order never
  matters and vectors survive restarts. `Dense()` L2-normalises, so cosine
  similarity is a dot product. Category/venue dominate the event vector;
  title/description words contribute a minority.
- **User profiles**: `rebuildUser` re-sums the user's full interaction history
  (weighted per behaviour: view/click 1, save 4, share/like 3, purchase 5) and
  stores the normalised embedding plus preferred categories/venues/times
  (weekend vs weekday, hour-of-day). A purchase reinforces the buyer's profile
  as `purchase x quantity`, and the event's popularity rises.
- **Recommendations**: published, future events are scored `cosine(user,
  event)`; a small popularity tie-break (never allowed to dominate content
  fit) and a category-grounding boost apply, events the user already
  interacted with are excluded, and the top-N is returned with **reason
  strings** ("Matches your Jazz interest", "At a venue you like", "Happening on
  a weekend"). Users with no profile get a **cold-start** feed of trending,
  popular upcoming events.
- **Similar events**: nearest neighbours of an event in the same embedding
  space, cached into the row's `similar_events`.
- **Caching**: per-user, per-type recommendations are cached for 5 minutes;
  a cache hit never serves an empty personalised feed (falls through to recompute).
  Every feed request is logged to `ai_queries` with latency and result ids.

Both `feature_version` and `model_version` are stamped onto every row: bump
`FeatureVersion`/`ModelVersion` (embedding.go / service.go) to force stale rows
to be recomputed on the next write/demand path.

## RabbitMQ

This service is a **consumer only** on the `donjo.events` topic exchange. It
declares its **own queue** (`donjo.ml.sync`) bound to exactly the catalog and
sales keys — no competing consumers, so it never races `donjo_event`,
`donjo_backend`, or `donjo_booking`:

| Routing key            | Effect |
|------------------------|--------|
| `event.created`, `event.updated` | Upsert the event document + recompute its embedding and popularity. |
| `event.published`      | Flip `is_published`/`status` so the event can enter recommendations. |
| `event.deleted`        | Remove the embedding and null its interactions. |
| `ticket.type.created`, `ticket.type.updated` | Merge the ticket into the stored event and re-vectorise it. |
| `ticket.purchased`     | Reinforce the buyer's profile (`purchase x quantity`) and bump the event's popularity. |
| `ticket.sale.released` | Acked and ignored — releases don't change embeddings. |
| `venue.created`, `venue.updated` | Store the venue doc so its events can be feature-augmented. |
| `venue.deleted`        | Acked and ignored (embeddings keep the venue tokens). |

The consumer acks only after the model write succeeds and requeues failures
with a short backoff, dropping a message after 20 consecutive failures to
avoid a hot requeue loop.

## API

| Method | Path                          | Auth   | Purpose |
|--------|-------------------------------|--------|---------|
| GET    | `/api/v1/recommendations`     | Bearer | Personalised feed: `?type=upcoming|trending` (default `upcoming`), `?limit=` (max 50). Returns `model_version`, `user_id`, and items each with `event_id`, `score`, `reasons[]` and the denormalised `event`. |
| GET    | `/api/v1/profile`             | Bearer | The caller's learned preferences: top categories, preferred venues/times, `interaction_count`, `model_version`. A user with no history gets `200` with an explanatory message instead of an error. |
| POST   | `/api/v1/interactions`        | Bearer | Record behaviour used to train the model: `{event_id, interaction_type, weight?, ...}`. Types: `view`, `click`, `save`, `share`, `like`, `purchase`. Idempotently rebuilds the profile. |
| GET    | `/api/v1/events/:id/similar`  | —      | Events most similar to `:id` by cosine similarity (`?limit=` max 20). `404` if the event is unknown to the model. |
| GET    | `/api/v1/events/:id`          | —      | The stored (denormalised) copy of an event used for rendering. `404` if not seen. |

```bash
# personalised upcoming feed
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8085/api/v1/recommendations?type=upcoming&limit=10"
# teach the model you like an event
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"event_id":"<id>","interaction_type":"save"}' \
  "http://localhost:8085/api/v1/interactions"
# similar events, no auth
curl "http://localhost:8085/api/v1/events/<id>/similar?limit=8"
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
  Every per-user route is scoped to the `user_id` claim from the token — the
  interaction payload cannot name a different victim, and profile/recommendation
  reads are tied to the caller's own id.
- **Reque loop protection**: consumer failures are backed off and finally
  dropped after 20 attempts, so a poison message can't pin a core.
- **Rate limiting**: per-IP fixed-window budget over the whole API (`429` on
  breach).
- **Body cap**: `http.MaxBytesReader` rejects oversized payloads (`400
  "request body too large"`) before unbounded parsing.
- **Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`;
  over TLS, `Strict-Transport-Security` is added.
- **Data at rest**: `db/` and `*.db*` are gitignored; never commit the SQLite
  file (contains user preference profiles and the query log).