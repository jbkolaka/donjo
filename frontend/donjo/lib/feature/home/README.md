# Home

Scaffolded feature directory (no code yet).

## Intended scope

Post-authentication home screen: personalised event rails from the Discovery ML
service (`/api/v1/recommendations`, `/api/v1/profile`), upcoming booked events
(bookings microservice) and a search entry point.

## Layout (planned)

```
lib/feature/home/
├── data/
│   ├── models/
│   └── repositories/           # HomeRepository aggregating discovery + bookings + search
└── presentation/
    └── bloc/                   # home_event / home_state / home_bloc (feeds from child blocs)
```

The home screen should compose existing feature blocs rather than re-fetch — it
lists alongside the child `DiscoveryBloc`, `EventsBloc` and `BookingsBloc`
already provided above it in the widget tree.