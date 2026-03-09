# T-023-03 Structure: Impersonation

## New Files

### `lib/haul_web/impersonation.ex`
Helper module centralizing impersonation logic.

Public functions:
- `active?(session_or_assigns)` — returns boolean
- `expired?(session_or_assigns)` — returns boolean (> 1 hour)
- `remaining_minutes(session_or_assigns)` — integer minutes remaining
- `start_session(conn, admin, slug)` — puts session keys, logs start, returns conn
- `end_session(conn, reason \\ :manual)` — clears keys, logs end/expiry, returns conn
- `validate_and_load(session)` — checks admin token + impersonation keys, returns `{:ok, admin, company}` or `:not_impersonating` or `:expired`

Session keys: `"impersonating_slug"`, `"impersonating_since"`, `"real_admin_id"`

### `test/haul_web/live/admin/impersonation_test.exs`
Comprehensive test file covering:
- Start impersonation (session keys set, redirect to /app)
- Banner rendering during impersonation
- Exit impersonation (keys cleared, redirect to /admin/accounts)
- Auto-expiry (1 hour limit)
- Privilege stacking blocked (/admin returns 404 during impersonation)
- Tenant users cannot trigger impersonation
- Admin logout clears impersonation
- Invalid slug handling

## Modified Files

### `lib/haul_web/controllers/admin_session_controller.ex`
Add two new actions:
- `impersonate/2` — validates slug, calls `Impersonation.start_session`, redirects to `/app`
- `exit_impersonation/2` — calls `Impersonation.end_session`, redirects to `/admin/accounts`

Modify existing:
- `delete/2` — also clear impersonation keys on admin logout

### `lib/haul_web/router.ex`
Add routes:
- In authenticated `/admin` scope: `post "/impersonate/:slug", AdminSessionController, :impersonate`
- In public `/admin` scope: `post "/exit-impersonation", AdminSessionController, :exit_impersonation`

### `lib/haul_web/plugs/require_admin.ex`
Add impersonation check in `call/2`:
- After successful admin verification, check for `impersonating_slug` in session
- If present: return 404 (block admin access during impersonation)
- Also check for expiry: if expired, clear keys and redirect

### `lib/haul_web/live/admin_auth_hooks.ex`
Add impersonation check in `on_mount(:require_admin)`:
- After successful admin load, check for `impersonating_slug` in session
- If present: halt + redirect to "/" (block LiveView admin access during impersonation)

### `lib/haul_web/live/auth_hooks.ex`
Add impersonation bypass in `on_mount(:require_auth)`:
- Before normal user JWT check, check for impersonation keys in session
- If impersonation active + valid admin JWT: bypass user auth
  - Set `current_user` to nil
  - Set `current_company` from impersonated slug
  - Set `impersonating: true`, `current_admin` assigns
  - Check expiry: if expired, redirect to `/admin` with flash

### `lib/haul_web/plugs/tenant_resolver.ex`
Add impersonation override in `call/2`:
- Before host-based resolution, check for `impersonating_slug` + valid admin session
- If present: resolve tenant from that slug instead of hostname
- Check expiry at plug level too

### `lib/haul_web/live/tenant_hook.ex`
Add impersonation awareness:
- Check for `impersonating_slug` in session
- If present: use that slug instead of `tenant_slug`

### `lib/haul_web/components/layouts/admin.html.heex`
Add impersonation banner at top of layout (before header):
- Fixed top bar with warning color (amber/orange)
- Shows: "Viewing as [company.name] ([slug]) — [time remaining] min — Exit"
- "Exit" is a form with POST to `/admin/exit-impersonation`
- Only renders when `@impersonating` assign is truthy

### `lib/haul_web/live/admin/account_detail_live.ex`
Enable impersonate button:
- Remove `disabled` attribute and "Coming soon" title
- Make it a form with POST to `/admin/impersonate/:slug`
- Only show when tenant is provisioned

### `test/support/conn_case.ex`
Add helper:
- `setup_admin_session/1` — creates admin, completes setup, returns conn with admin session

## Module Dependencies

```
Impersonation (new)
├── used by AdminSessionController (start/end)
├── used by RequireAdmin plug (block check)
├── used by AdminAuthHooks (block check)
├── used by AuthHooks (bypass check)
├── used by TenantResolver plug (override check)
└── used by TenantHook (override check)
```

## Change Ordering

1. Create `Impersonation` helper module (no dependencies)
2. Modify `AdminSessionController` (depends on Impersonation)
3. Modify `router.ex` (depends on controller actions)
4. Modify `RequireAdmin` plug (depends on Impersonation)
5. Modify `AdminAuthHooks` (depends on Impersonation)
6. Modify `TenantResolver` plug (depends on Impersonation)
7. Modify `TenantHook` (depends on Impersonation)
8. Modify `AuthHooks` (depends on Impersonation)
9. Modify `admin.html.heex` layout (banner)
10. Modify `AccountDetailLive` (enable button)
11. Write tests
