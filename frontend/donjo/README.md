# Donjo Flutter App

Flutter client for the Donjo event platform. The app talks to the Go
microservice backend exclusively through the **API Gateway** (port 8080),
which routes `/api/v1/...` paths to individual services.

## Stack

- **Flutter** (SDK `^3.12.2`) with **Dart 3** sealed types
- **flutter_bloc** `^9.1.1` for state management
- **dio** `^5.11.0` for HTTP (auth interceptor + 401 session handling)
- **flutter_secure_storage** (tokens) + **shared_preferences** (light storage)
- **device_info_plus** (device registration for push)
- `flutter_lints` via `analysis_options.yaml`

## Architecture

Feature-first layout, one folder per microservice feature. Every feature with a
backend dependency follows the same three-layer pattern and the `authentication`
feature is the reference template for blocs:

```
lib/
├── main.dart                      # app bootstrap, root MultiBlocProvider
├── core/                          # shared, feature-agnostic code
│   ├── config/backend_uri.dart    # per-service /api/v1 path constants
│   ├── network/                   # dio factory + ApiException mapping
│   ├── storage/token_store.dart   # secure token persistence
│   ├── theme/                     # app palette, typography, effects
│   ├── grid/ motion/ widgets/ utils/
└── feature/
    ├── <feature>/
    │   ├── data/
    │   │   ├── models/            # typed JSON models (+ drafts/requests)
    │   │   └── repositories/      # dio calls, maps ApiException
    │   └── presentation/bloc/     # <feature>_event / _state / _bloc
    └── README.md                  # per-feature "how it works"
```

### Feature → backend mapping

| Feature      | Microservice      | Routes (via gateway `/api/v1`)                                  |
|--------------|-------------------|-----------------------------------------------------------------|
| authentication | auth           | auth/register, auth/login, auth/me, auth/logout, password reset |
| app          | gateway (8080)    | /health, /meta                                                   |
| events       | events            | events, venues, tickets (+ publish/unpublish, purchase)          |
| bookings     | bookings          | bookings/my, instances, waitlist, scan/locations, check-in       |
| payments     | payments          | transactions, escrows, wallet                                    |
| search       | search            | search                                                           |
| discovery    | discovery/ML      | recommendations, profile, events/:id/similar, interactions       |
| notifications| notifications     | notifications, feed, devices, templates                          |
| gateway      | gateway (8080)    | /health                                                          |

Each feature folder ships a `README.md` describing how it works in detail.

## How the data flows

```
UI widget ──dispatches──▶ BlocEvent ──▶ Bloc ──▶ Repository ──▶ dio ──▶ Gateway ──▶ Microservice
                             ▲                                          │
                             └──── BlocState (loading/loaded/failure) ◀──┘
```

1. Widgets **dispatch sealed `XYZEvent`s** — never call dio directly.
2. The `Bloc` maps events → repository calls and emits a **status**
   (`initial → loading → loaded/failure`).
3. Repositories build on `createZoaDio(tokenStore: ...)` which auto-attaches
   the bearer token and triggers `onUnauthorized` (session wipe + return to
   sign-in) when the backend replies 401.
4. Network errors are normalized to `ApiException` and re-exposed on state as
   `XYZError{message, fields}` (fields drive per-input inline validation).
5. Every state exposes `copyWith` and a `busy` getter; screens use
   `BlocBuilder`/`BlocListener` on the single shared bloc instance.

## Common conventions

- 3 files per feature bloc: `<feature>_event.dart`, `<feature>_state.dart`,
  `<feature>_bloc.dart` (auth is the template — keep it unmodified).
- JSON uses `snake_case` from the API, mapped to `camelCase` Dart fields.
- 422 responses can be meaningful domain results (e.g. rejected check-in scans
  return a `CheckinResult` instead of throwing).

## Getting started

```sh
flutter pub get
flutter run                # target a device/emulator; gateway must be reachable
```

Point the gateway base URL in `lib/core/config/backend_uri.dart` before running
a device (emulator uses `10.0.2.2`).

## Verify

```sh
flutter analyze            # zero issues expected
flutter test               # widget/unit tests under test/
```

## Asset & platform scaffolding

Generated Flutter scaffolding for `android/`, `ios/`, `web/`, `linux/`,
`macos/`, `windows/` lives beside `lib/`; image assets are declared in
`pubspec.yaml` under `assets/images/` and referenced by the splash/landing
screens.