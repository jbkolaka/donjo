# Project donjo_search

Search: a read-path microservice that mirrors the `donjo_event` catalog into
**Elasticsearch** so organizers and shoppers can find events, tickets and
venues quickly. It never writes to the source of truth — instead it consumes
the same catalog events others do, on its **own** RabbitMQ queue
(`donjo.search.sync`), and keeps three ES indices warm: `donjo_events`,
`donjo_tickets` and `donjo_venues`. The public search endpoint is stateless
and unauthenticated; the raw indices hold only searchable copies of public
catalog data (no user secrets).

## Environment variables

Required configuration:

```bash
PORT=8084
ELASTICSEARCH_URL=http://localhost:9200
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
CORS_ALLOWED_ORIGINS=http://localhost:5173
```

- `ELASTICSEARCH_URL` is the base URL of the ES node. This service needs only
  **HTTP client access**; it issues `HEAD`/`PUT` index-mapping calls at boot,
  then plain document `<index>/_doc/:id` and `_update_by_query` calls. There is
  no scraping/ingestion into a second datastore — Elasticsearch is the search
  index.
- `RABBITMQ_URL` is the AMQP URL of the shared broker (default
  `amqp://guest:guest@localhost:5672/`). When the broker is unreachable the
  service **degrades gracefully**: it keeps serving HTTP reads from whatever
  is already indexed, and the broker queues catalog events for when the
  consumer reconnects.
- `CORS_ALLOWED_ORIGINS` is a comma-separated allow-list (default
  `http://localhost:5173`).

Optional hardening configuration:

```bash
# Elasticsearch basic-auth credentials, when xpack security is enabled
# on the node (kept off in dev; ES 8.x is created with
#   podman run -d --name donjo-es -p 9200:9200 -p 9300:9300 \
#     -e discovery.type=single-node -e xpack.security.enabled=false \
#     -e ES_JAVA_OPTS="-Xms512m -Xmx512m" \
#     docker.elastic.co/elasticsearch/elasticsearch:8.15.5)
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=

# TLS: both must be set to serve HTTPS; otherwise plain HTTP (dev).
TLS_CERT_FILE=./certs/fullchain.pem
TLS_KEY_FILE=./certs/privkey.pem

# Rate limits (per client IP, fixed 60s window).
RATE_LIMIT_REQUESTS=300          # global /api/v1 budget

# Request body cap in bytes (default 1 MiB).
MAX_BODY_BYTES=1048576
```

## Authentication

Unlike the transactional services, search is a **public read API** — no
`Authorization` header is required or checked. Results only ever expose public
catalog fields (`title`, `city`, `price`, availability, …); there is no PII and
no way to scope down to a user. Rate limiting and the body cap still apply.

## Search index

Elasticsearch runs as its own container `donjo-es`. The index is designed
around three document kinds that mirror the catalog:

| Index           | Document id     | What it holds                                                          |
|-----------------|-----------------|------------------------------------------------------------------------|
| `donjo_events`  | event id        | Event + its (current) ticket list + live aggregates. Each event also carries `tickets[]` (nested) plus `available_tickets`, `tickets_sold`, `revenue`, `min/max_ticket_price`, `is_published`, `status`. |
| `donjo_tickets` | ticket id       | Standalone ticket, denormalised with its parent event context (`event_title`/`event_slug`/`event_category`/`event_city`/`event_start_time`, `event_is_published`) plus `price`, `availability`, `sold`, `is_active`. |
| `donjo_venues`  | venue id        | Venue name, type, address, city, county, country, capacity, lat/long.  |

Mappings use a custom `asciifold` analyzer so accented text (`é` → `e`,
`ü` → `u`) matches queries typed without accents. Tickets/venues are kept one
document per ticket/venue; the event doc's nested `tickets[]` is a projection
updated on each ticket change so per-event availability and price bands are
always current.

## RabbitMQ

The service is a **consumer only** on the `donjo.events` topic exchange. It
declares its **own queue** (`donjo.search.sync`) bound to exactly the catalog
keys it cares about — no competing consumers, so it never races `donjo_event`
or `donjo_backend`:

| Routing key            | Effect |
|------------------------|--------|
| `event.created`, `event.updated` | Upsert the full event doc (and its tickets/aggregates). |
| `event.published`      | Flip `is_published`/`status` on the event doc and propagate `event_is_published` to its ticket docs. |
| `event.deleted`        | Delete the event doc. |
| `ticket.type.created`, `ticket.type.updated` | Upsert the standalone ticket doc and re-sync the parent event's nested `tickets[]` + aggregates. |
| `ticket.purchased`     | Decrement availability / bump sold + revenue on the event and ticket docs (painless script). |
| `ticket.sale.released` | Return released stock to availability (painless script). |
| `venue.created`, `venue.updated`, `venue.deleted` | Upsert / delete the venue doc. |

The consumer acks only after the index write succeeds. A transient failure
(ES busy, broker blip) requeues with a short backoff; a message that keeps
failing is **dropped after 20 consecutive attempts** to avoid a hot requeue
loop hammering Elasticsearch (e.g. its inline-script compilation rate limit).

## Search API

`GET /api/v1/search` — stateless, unauthenticated.

| Param          | Meaning                                                        |
|----------------|----------------------------------------------------------------|
| `q`            | Free text (title/description/category/tags for events; name/event for tickets; name/address for venues). |
| `type`         | `events` (default) \| `tickets` \| `venues`.                    |
| `category`     | Exact event category (events only).                            |
| `city`, `country` | Exact city / country filters.                               |
| `event_type`   | `physical` / `virtual` / … (events only).                      |
| `is_virtual`   | `true`\|`false`.                                               |
| `min_price`, `max_price` | Price band on `min_ticket_price` (events).            |
| `min_capacity` | Minimum `total_capacity` (events).                             |
| `date_from`, `date_to` | RFC3339 window on `start_time` (events).             |
| `status`       | Default `published` (events).                                  |
| `sort`         | `relevance` \| `date` \| `price_asc` \| `price_desc` (events). |
| `page`, `size` | Pagination (`size` clamped to 100).                            |

Events filter to **published, non-private, not-yet-ended** by default;
tickets filter to `is_active` with `availability > 0`. Response shape:
`{ total, page, size, hits: [{ id, type, score, source }] }`.

```bash
# find events in Nairobi
curl "http://localhost:8084/api/v1/search?q=jazz&type=events&city=Nairobi"
# cheap tickets for the weekend
curl "http://localhost:8084/api/v1/search?q=weekend&type=tickets&max_price=1500"
# a venue by name
curl "http://localhost:8084/api/v1/search?q=fort&type=venues"
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

Run the test suite:
```bash
make test
```

Clean up binary from the last build:
```bash
make clean
```

## Security & hardening

- **No user data**: the index only mirrors public catalog fields; the service
  never sees or stores user credentials, and the search endpoint is public by
  design. There is no SQL to inject — all queries are assembled as JSON and
  sent to ES as structured docs, and user free-text goes through ES's query DSL
  (`multi_match`), never concatenated into scripts.
- **Stateless reads**: a bootstrapped index keeps serving even if the broker or
  an upstream goes down; index writes are idempotent upserts.
- **Requene-loop protection**: repeated failures are backed off and ultimately
  dropped, so a poison message can't pin a core or trip ES's script-compile
  rate limiter in a self-sustaining loop.
- **Rate limiting**: per-IP fixed-window budget over the whole API (`429` on
  breach).
- **Body cap**: `http.MaxBytesReader` rejects oversized payloads (`400`) — this
  applies to the (tiny) request surface, since search is GET-only.
- **Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`;
  over TLS, `Strict-Transport-Security` is added.
