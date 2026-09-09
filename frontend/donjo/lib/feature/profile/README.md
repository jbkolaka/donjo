# Profile

Scaffolded feature directory (no code yet).

## Intended scope

Signed-in user profile: `GET /api/v1/auth/me` session data, preferences, and
discovery preferences surfaced from the ML service
(`GET /api/v1/profile` → `UserProfile`).

## Layout (planned)

```
lib/feature/profile/
├── data/
│   ├── models/
│   └── repositories/           # ProfileRepository (auth/me + ML profile)
└── presentation/
    └── bloc/                   # profile_event / profile_state / profile_bloc
```

Follows the same pattern as the other feature blocs (sealed events, status enum,
`copyWith` state, `ApiException` → failure).