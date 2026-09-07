# Project donjo_backend

One Paragraph of project description goes here

## Environment variables

Required configuration:

```bash
PORT=8080
BLUEPRINT_DB_URL=donjo.db
UPLOAD_DIR=uploads
PUBLIC_BASE_URL=http://localhost:8080
JWT_SECRET=<long-random-string>
DATA_ENCRYPTION_KEY=<64-hex-chars>
DATA_INDEX_KEY=<64-hex-chars>
```

- `JWT_SECRET` signs access tokens. It must be a random string of 32+
  characters; the app refuses to start in production without it.
- `DATA_ENCRYPTION_KEY` / `DATA_INDEX_KEY` protect sensitive PII (email,
  phone) **and the TOTP secret**. Emails, phone numbers, and 2FA secrets are
  stored AES-256-GCM encrypted and looked up via keyed HMAC blind indexes
  (`email_hash`, `phone_hash`, `mpesa_hash`) — never as plaintext.
  Array/object columns (interests, social_links, etc.) are stored as JSON
  text and not encrypted.

Generate the two data keys with:

```bash
go run ./cmd/genkeys
```

Missing/malformed keys cause registration/login to fail (the service refuses
to write plaintext).

- `UPLOAD_DIR` is the local directory where uploaded profile pictures are
  stored (default `uploads`).
- `PUBLIC_BASE_URL` is the public base URL used to build the served image URLs
  (default `http://localhost:8080`).

Optional hardening configuration:

```bash
# TLS: both must be set to serve HTTPS; otherwise plain HTTP (dev).
TLS_CERT_FILE=./certs/fullchain.pem
TLS_KEY_FILE=./certs/privkey.pem

# Per-IP rate limits (fixed 60s window).
AUTH_RATE_LIMIT_REQUESTS=20    # register/login/refresh/password-reset group
API_RATE_LIMIT_REQUESTS=300    # authenticated account endpoints

# Request body cap in bytes (default 5 MiB, covers profile-image uploads).
MAX_BODY_BYTES=5242880
```

All responses carry `X-Content-Type-Options`, `X-Frame-Options`,
`Referrer-Policy`, `Permissions-Policy`, and a `default-src 'none'`
Content-Security-Policy; over TLS, `Strict-Transport-Security` is added.
The SQLite database (`db/`) is gitignored.

## Profile Images

Authenticated users can upload a profile picture. The bytes are stored only in
a local directory (`UPLOAD_DIR`) under a random, unpredictable filename; the
database persists only the public URL. Images are served from `PUBLIC_BASE_URL`
like a private CDN.

| Method | Path                 | Body                            | Purpose |
|--------|----------------------|---------------------------------|---------|
| POST   | `/api/v1/me/profile-image` | `multipart/form-data`, field `image` (Bearer access token) | Upload a picture; stores the file locally and persists its public URL on the profile. Responds `{"profile_image": "<url>"}` and serves it at `GET /uploads/<name>`. |

Validation:

- Only raster formats are accepted: `image/jpeg`, `image/png`, `image/webp`,
  `image/gif`. Type is determined by **sniffing** the file contents
  (`http.DetectContentType`), never by the client filename or extension.
- **SVG is rejected** because it can carry embedded scripts and becomes an
  XSS vector when served.
- Size cap is 5 MiB (`413` when exceeded).
- Uploading again removes the previous file automatically so storage does not
  leak.

The old file is removed after a successful replacement, and paths are sanitised
so a crafted URL cannot escape the upload directory.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Two-Factor Authentication (TOTP)

TOTP codes are RFC 6238 compatible with **Google Authenticator** (6 digits,
SHA-1, 30-second period). Flow:

1. `POST /api/v1/auth/login` with `{email, password}` — if 2FA is enabled and
   no `two_factor_code` is supplied, respond `200 {"tfa_required": true}`.
2. Send `two_factor_code` on retry to complete login.

> **Anti-enumeration:** unknown email, wrong password, and missing/wrong 2FA
> code all return the identical `200 {"tfa_required": true}` response, so the
> login endpoint cannot be used to discover whether an account exists or
> validate passwords/2FA state.

2FA endpoints (Bearer token required):

| Method | Path             | Body        | Purpose                                  |
|--------|------------------|-------------|------------------------------------------|
| GET    | `/api/v1/2fa/status` | —        | Enabled? (`{enabled: bool}`)             |
| POST   | `/api/v1/2fa/setup`  | —        | Returns `otpauth_url` + `secret` (QR)    |
| POST   | `/api/v1/2fa/verify` | `{code}`  | Confirm code from Google Authenticator, enables 2FA |
| POST   | `/api/v1/2fa/disable`| `{code}`  | Disable 2FA (requires valid current code)|

Client flows: render `otpauth_url` as a QR code for Google Authenticator to
scan, then call `/2fa/verify` with the 6-digit code shown on the phone.

## Sessions & Refreshing

On successful login you receive both an **access token** (short-lived JWT,
15 min) and an **opaque refresh token** (30 days). Only the SHA-256 hash of
the refresh token is stored server-side.

| Method | Path                    | Body                          | Purpose |
|--------|-------------------------|-------------------------------|---------|
| POST   | `/api/v1/auth/refresh`  | `{refresh_token}`             | Rotate the refresh token; returns a new access + refresh pair. The old token is **one-time use** — a reused or revoked token is rejected with `401`. |
| POST   | `/api/v1/auth/logout`   | `{refresh_token}`             | Revoke the presented refresh token. Works even after the access token expires. |
| POST   | `/api/v1/auth/logout-all`| — (Bearer access token)      | Revoke every active refresh token for the authenticated user. |

Apply the new access token to subsequent requests via `Authorization: Bearer
<access_token>`.

### Refresh-token reuse detection

Refresh tokens are one-time-use and rotated on every `/refresh`. If a token
that was already rotated is presented again (a stolen-token replay), every
session for that user is revoked and the attempt is rejected with `401`.

## Password Reset

| Method | Path                        | Body                  | Purpose |
|--------|-----------------------------|-----------------------|---------|
| POST   | `/api/v1/auth/password/forgot` | `{email}`           | Issue a one-time, 1-hour reset token. The response is **identical whether or not the account exists** (anti-enumeration); only real accounts actually receive a redeemable token. |
| POST   | `/api/v1/auth/password/reset`  | `{token, new_password}` | Set the new password. The token is single-use; after a successful reset all outstanding resets are cancelled and **every session is revoked**, forcing re-authentication everywhere. |

> The reset link is emailed to the account's address over SMTP (`SMTP_HOST`,
> `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`). When SMTP is not
> configured the mailer runs in no-op mode and only logs, so the API still
> responds identically whether or not the account exists (anti-enumeration).

## Sessions

Authenticated users can list and individually revoke their sessions (each
refresh token — and thus each signed-in device — is one session).

| Method | Path                          | Body   | Purpose |
|--------|-------------------------------|--------|---------|
| GET    | `/api/v1/sessions`            | — (Bearer access token) | List all sessions for the authenticated user, including device/browser/IP and revoked state. |
| POST   | `/api/v1/sessions/:id/revoke` | — (Bearer access token) | Revoke a single session. Owner-scoped: a foreign or nonexistent session id returns `404`. |

> Revoking a session invalidates its refresh token immediately; any access
> token already issued for it stays valid only until it expires.

## Brute-force protection (persistent)

Login is throttled in the **database**, so the guard survives restarts and
coordinates across server instances:

- Consecutive failures per account (`users.failed_login_attempts`) lock that
  account for 15 minutes after 5 failures (`users.locked_until`).
- A windowed attempt budget per identifier (including unknown emails) lives in
  `rate_limits`, so probing arbitrary addresses is slowed identically to real
  accounts (no enumeration via timing/rate-limit).
- Unknown emails run a dummy bcrypt compare so known/unknown response time is
  indistinguishable.

## MakeFile

Run build make command with tests
```bash
make all
```

Build the application
```bash
make build
```

Run the application
```bash
make run
```

Live reload the application:
```bash
make watch
```

Run the test suite:
```bash
make test
```

Clean up binary from the last build:
```bash
make clean
```
