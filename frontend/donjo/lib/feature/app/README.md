# App

App-level bootstrap: splash routing and gateway/meta bootstrap data.

## Backend

Talks to the **gateway** (root port 8080) directly:

- `GET /health` → `HealthStatus`
- `GET /meta` → `MetaCatalog`

## Layout

```
lib/feature/app/
├── data/
│   ├── models/app_model.dart           # HealthStatus, MaterialInfo, MetaCatalog
│   └── repositories/app_repository.dart
└── presentation/
    └── pages/splash_screen.dart
```

## How it works

- `AppRepository` builds its own dio instance through `createZoaDio` (still attaches
  the bearer token when present).
- `health()` pings the gateway `/health`; `meta()` pulls the material catalog used
  for recycling/label lookups.
- The splash screen gates app startup, then routes to `InitialScreen` (auth) or the
  landing/home screens once startup is complete.