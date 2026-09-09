# Bookings

Tickets a user owns, booking instances, waiting lists, venue scan locations and
event check-in.

## Backend

Talks to the **bookings** microservice through the gateway:

- `GET /api/v1/bookings/my`, `GET /api/v1/bookings/:id`
- instance flows: `GET /api/v1/instances/:id`, assign to a booking, share, claim,
  sell to resale, buy from resale
- waitlist: `GET /api/v1/waitlist`, `PUT /api/v1/waitlist/:id`
- check-in: instance by code + `GET /api/v1/scan/locations` (scanner support)

## Layout

```
lib/feature/bookings/
├── data/
│   ├── models/booking_models.dart
│   └── repositories/booking_repository.dart
└── presentation/bloc/                   # bookings_event / bookings_state / bookings_bloc
```

## How it works

1. UI dispatches `MyBookingsLoaded`, `BookingDetailRequested`, `BookingInstancesLoaded`,
   instance assignment/sharing/claim/resale actions, waitlist updates,
   check-in scans and scan-location loads.
2. `BookingsBloc` delegates to `BookingRepository`, emitting
   `BookingsStatus.loading → loaded/failure`.
3. Check-in is special: the backend rejects rejected scans with **HTTP 422**.
   The repository catches that and returns a `CheckinResult` (accepted/rejected
   status) instead of throwing, so the scanner UI can show a friendly verdict.
4. State exposes the bookings list, selected booking detail, its instances,
   waitlist entries and scan locations/check-in results.

The `BookingInstance` model carries the linking pin/should-pin state that drives
the claim/sort flow of generous tickets.