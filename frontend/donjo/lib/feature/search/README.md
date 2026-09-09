# Search

Text + filter search across events (and other indexed entities).

## Backend

Talks to the **search** microservice through the gateway:

- `GET /api/v1/search?q=...&type=...&...` → `SearchResult`
- pagination / filters via `SearchFilters.toQueryParameters()`

## Layout

```
lib/feature/search/
├── data/
│   ├── models/search_models.dart
│   └── repositories/search_repository.dart
└── presentation/bloc/                   # search_event / search_state / search_bloc
```

## How it works

1. The search bar dispatches `SearchStarted(filters)` (`SearchFilters` holds the
   query text, entity `type` filter, region/date constraints and page/limit).
2. `SearchBloc` sets status to `searching`, calls
   `SearchRepository.search(filters)` and emits `loaded` with a `SearchResult`.
3. Clears are explicit events: `SearchResultsCleared` resets status/result/filters,
   `SearchErrorCleared` only dismisses the last error.
4. Errors surface as `SearchError{message, fields}` on the state; the UI shows the
   empty/error slot and keeps the previous results until a new search completes.