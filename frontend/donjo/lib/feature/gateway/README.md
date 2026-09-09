# Gateway

Health/connectivity monitor against the API Gateway — the app's edge to all
microservices (everything else still routes through port 8080).

## Backend

Talks to the **gateway** service directly (no service prefix):

- `GET /health` → `GatewayHealthStatus`
- `GET /api/v1` → API version info

## Layout

```
lib/feature/gateway/
├── data/
│   ├── models/gateway_models.dart
│   └── repositories/gateway_repository.dart
└── presentation/bloc/                   # gateway_event / gateway_state / gateway_bloc
```

## How it works

1. UI dispatches `GatewayPingRequested` (e.g. on startup, connectivity loss, or a
   pull-to-refresh on an error banner).
2. `GatewayBloc` calls `GatewayRepository.health()`; the result drives
   `GatewayStatus.up | down | failure`.
3. The `isUp` getter on the state is convenience for banners/status dots:
   `status == up && health.isUp`.
4. Because the gateway routes to every microservice, a healthy gateway + healthy
   `/health` is the app's primary "is the backend reachable" signal.