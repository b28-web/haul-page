# T-023-01 Research: Superadmin Auth

## Existing Auth System

### User Resource (`lib/haul/accounts/user.ex`)
- Ash resource with `AshAuthentication` extension, `AshPostgres.DataLayer`, `Ash.Policy.Authorizer`
- Multi-tenant via `postgres > multitenancy > strategy :context`
- Password strategy with identity field `:email`, resettable, magic_link
- Token resource: `Haul.Accounts.Token` (JWT, `require_token_presence_for_authentication?: true`)
- Signing secret from `Application.fetch_env(:haul, :token_signing_secret)`
- Attributes: `id` (uuid), `email` (ci_string), `name`, `role` (enum), `phone`, `hashed_password`, `active`, timestamps

### Token Resource (`lib/haul/accounts/token.ex`)
- Simple resource with `AshAuthentication.TokenResource` extension
- Multi-tenant `:context` strategy, table `tokens`

### Accounts Domain (`lib/haul/accounts.ex`)
- Registers Company, User, Token
- No AdminUser resources exist yet

### Router (`lib/haul_web/router.ex`)
- `:browser` pipeline: session, CSRF, TenantResolver, EnsureChatSession
- Public tenant routes under `/` with `TenantHook` live_session
- `/app` scope: public (signup, login, session controller) + authenticated live_session
- Authenticated live_session uses `on_mount: [{HaulWeb.AuthHooks, :require_auth}]`, layout `{HaulWeb.Layouts, :admin}`
- No `/admin` scope exists yet

### AuthHooks (`lib/haul_web/live/auth_hooks.ex`)
- `on_mount(:require_auth, ...)` reads `session["user_token"]` and `session["tenant"]`
- Verifies JWT via `AshAuthentication.Jwt.verify`, resolves subject to user
- Checks role is `:owner` or `:dispatcher`
- Redirects to `/app/login` on failure

### AppSessionController (`lib/haul_web/controllers/app_session_controller.ex`)
- `create`: stores `user_token` + `tenant` in session, renews session
- `delete`: drops session, redirects to `/app/login`

### Application (`lib/haul/application.ex`)
- Supervisor children: Telemetry, Repo, Oban, DNSCluster, PubSub, RateLimiter, Endpoint
- Pre-startup: `Haul.Content.Loader.load!()`
- No admin bootstrap logic exists

### Endpoint (`lib/haul_web/endpoint.ex`)
- Cookie session: key `_haul_key`, signing_salt `8v5yFT1O`, same_site `Lax`
- Single session config shared across all routes

### Layouts
- `root.html.heex`: HTML skeleton, theme system, Stripe.js
- `admin.html.heex`: sidebar + header for operator `/app` panel
- `Layouts` module (`layouts.ex`): `embed_templates "layouts/*"`, defines `app/1`, `flash_group/1`, `sidebar_link/1`, `theme_toggle/0`
- No superadmin layout exists

### LoginLive (`lib/haul_web/live/app/login_live.ex`)
- Resolves tenant from session
- Calls `User.sign_in_with_password` with tenant, gets JWT from `__metadata__.token`
- Posts hidden form to `/app/session` via `phx-trigger-action`

### Migrations
- Latest: `20260309155918_create_ai_cost_entries.exs`
- Ash migrations auto-generated via `ash_postgres.generate_migrations`

## Key Constraints

1. **AdminUser must be in public schema** — not tenant-scoped, unlike User/Token
2. **Separate auth flow** — different session key (`_admin_user_token`), different hooks, different controller
3. **No AshAuthentication for AdminUser** — the ticket's bootstrap flow (env var → setup token → password set) doesn't fit AshAuthentication's built-in strategies. Manual password hashing + verification is simpler and more secure for single-use setup tokens
4. **Session isolation** — admin and tenant sessions must be independent (different session keys)
5. **404 not 403** — all unauthorized admin access returns 404 to avoid revealing route existence
6. **Setup token security** — store SHA-256 hash, compare with timing-safe function, single-use

## Patterns to Follow

- Ash resource definition style (from user.ex/token.ex)
- Router scope + pipeline pattern (from existing `/app` scope)
- LiveView on_mount hooks (from auth_hooks.ex)
- Session controller pattern (from app_session_controller.ex)
- Layout module + template (from layouts.ex + admin.html.heex)
- Migration naming convention (timestamp_description.exs)

## Open Questions

1. Should AdminUser use AshAuthentication or manual password hashing? The ticket says "AshAuthentication with password strategy" but the bootstrap flow (env var setup token) is custom. We can use AshAuthentication for the sign-in part and manual logic for bootstrap.
2. Where should the bootstrap module live? `Haul.Admin.Bootstrap` seems natural.
3. Should AdminUser have its own Ash domain (`Haul.Admin`) or join `Haul.Accounts`? Separate domain keeps concerns clean.
