# Authentication

Handles registration, sign-in, session restore and sign-out for the Donjo app.

## Backend

Talks to the **auth** microservice via the API Gateway (`BaseUri.authUri`):

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET  /api/v1/auth/me`
- `POST /api/v1/auth/logout`
- password reset flows

## Layout (feature-first, BLoC)

```
lib/feature/authentication/
├── data/
│   ├── model/auth_models.dart          # AuthSession, User, request DTOs
│   └── repositories/auth_repository.dart
└── presentation/
    ├── bloc/                            # auth_event / auth_state / auth_bloc
    ├── pages/                           # initial, signin, signup, forgot-password
    └── widgets/                         # shared input/theme widgets
```

## How it works

1. `main.dart` starts an `AuthBloc` and immediately fires `AuthCheckRequested`.
2. `AuthRepositoryImpl` reads the persisted token from `TokenStore`.
   - Token present → `GET /auth/me` to restore the session → `AuthState.authenticated`.
   - Token missing/expired → `AuthState.unauthenticated`.
   - A 401 from any later request triggers `onUnauthorized`, which clears the session
     and returns the app to the sign-in screen.
3. Sign-in/register pages dispatch `SignInRequested` / `SignUpRequested`. The bloc
   calls the repository, stores the token via `TokenStore`, and emits
   `authenticated` with the `AuthSession`.
4. Sign-out dispatches `SignOutRequested`; the token is revoked and cleared locally.

All screens react to the single `AuthBloc` provided at the app root. This feature is
the pattern template for the other feature blocs.