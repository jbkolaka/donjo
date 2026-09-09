# Landing Page

Static placeholder screen greeting the user before authentication.

## State

Pure widget — no data layer yet. Renders the "Donjo" wordmark full-screen inside a
`Scaffold`.

Route entry: `InitialScreen` decides between this landing page and the sign-in flow
based on `AuthState`.

## Next steps

When the auth flow is wired to a first-run experience, this page will take a
"Get started" CTA that dispatches `SignUpRequested` / navigates to sign-in.