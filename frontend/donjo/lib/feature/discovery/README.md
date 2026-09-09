# Discovery

ML-powered personalisation: recommended events, the user's inferred profile and
similar-event suggestions.

## Backend

Talks to the **discovery/ML** microservice through the gateway:

- `GET /api/v1/recommendations?type=upcoming&limit=10` → `RecResult`
- `GET /api/v1/profile` → `UserProfile`
- `GET /api/v1/events/:id/similar?limit=8` → `SimilarEventsResult`
- `POST /api/v1/interactions` → `InteractionRequest`
- `POST /api/v1/events/:id/interaction`

## Layout

```
lib/feature/discovery/
├── data/
│   ├── models/discovery_models.dart    # UserProfile, Rec*, InteractionRequest
│   └── repositories/discovery_repository.dart   # + SimilarEventsResult
└── presentation/bloc/                   # discovery_event / discovery_state / discovery_bloc
```

## How it works

1. `RecommendationsLoaded` fetches personalised events (`type`/`limit`);
   `ProfileLoaded` fetches `UserProfile` (model version, interaction count,
   preferences by categories/venues/times, last-calculated timestamp);
   `SimilarEventsLoaded(eventId)` fetches the "more like this" rail.
2. Viewing/clicking/toggling interest dispatches `InteractionRecorded(request)`;
   the bloc records it and flags `interactionRecorded` so the UI can trigger a
   profile refresh.
3. `DiscoveryBloc` keeps the three payloads (recommendations, profile, similar)
   in one state via `copyWith`; status is `loading → loaded/failure`.
4. All state persists only in memory for now — the ML server does the heavy lifting
   and recomputes the user profile server-side.