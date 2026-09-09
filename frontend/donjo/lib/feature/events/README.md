# Events

Event browsing, detail and full event/venue/ticket management.

## Backend

Talks to the **events** microservice through the gateway:

- `GET /api/v1/events` (list + filters/type), `GET /api/v1/events/:id`
- `POST/PUT/DELETE /api/v1/events`
- `POST /api/v1/events/:id/publish | /unpublish`
- venue CRUD under `/api/v1/venues`
- ticket CRUD under `/api/v1/events/:id/tickets`
- `POST /api/v1/events/:id/tickets/purchase` → payment-escrow style purchase

## Layout

```
lib/feature/events/
├── data/
│   ├── models/event_models.dart        # Event, Venue, Ticket + draft/request DTOs
│   └── repositories/event_repository.dart
└── presentation/bloc/                   # events_event / events_state / events_bloc
```

## How it works

1. UI dispatch events like `EventsLoaded`, `EventDetailRequested`,
   `TicketsRequested`, `EventLiked`, `EventCreated`, `PurchaseTicketRequested`.
2. `EventsBloc` maps each event to a repository call and emits a
   `EventsStatus` (`loading → loaded/failure`).
3. State holds the catalogue, selected event, venues, tickets and the
   purchase result; widgets rebuild via `BlocBuilder`.
4. Errors arrive as `ApiException` and become `EventsError{message, fields}` on
   the state (fields map drives per-input inline validation).

`EventListQuery` bundles the catalogue filters (type, location, date range, page/limit).