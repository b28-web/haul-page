# T-023-03 Research: Impersonation

## Objective

Superadmin needs to view `/app` panel as any tenant operator to debug/test. Must be secure, auditable, time-limited.

## Existing Infrastructure

### Admin Authentication
- **RequireAdmin plug** (`lib/haul_web/plugs/require_admin.ex`): Reads `_admin_user_token` from session, verifies JWT, resolves AdminUser, checks `setup_completed: true`. Returns 404 on failure.
- **AdminAuthHooks** (`lib/haul_web/live/admin_auth_hooks.ex`): LiveView `on_mount(:require_admin)` — same JWT verification. Redirects to "/" on failure.
- **AdminSessionController** (`lib/haul_web/controllers/admin_session_controller.ex`): `create/2` stores JWT in `_admin_user_token`, `delete/2` clears it.

### Tenant Authentication (for /app)
- **AuthHooks** (`lib/haul_web/live/auth_hooks.ex`): `on_mount(:require_auth)` reads `user_token` + `tenant` from session. Verifies JWT against tenant User, loads Company. Requires `:owner` or `:dispatcher` role.
- **TenantResolver plug** (`lib/haul_web/plugs/tenant_resolver.ex`): Resolves tenant from Host header (custom domain → subdomain → fallback). Sets `current_tenant`, `tenant`, `is_platform_host` assigns. Stores `tenant_slug` in session.
- **TenantHook** (`lib/haul_web/live/tenant_hook.ex`): LiveView hook reads `tenant_slug` from session, loads Company, assigns tenant context.

### Router Structure
- `/admin` pipeline uses `admin_browser` (no TenantResolver) + `RequireAdmin` plug
- `/admin` authenticated routes use `:superadmin` live_session with `AdminAuthHooks.require_admin`
- `/app` routes use `:browser` pipeline (includes TenantResolver) + `:authenticated` live_session with `AuthHooks.require_auth`
- Public routes use `:browser` pipeline with TenantResolver + `:tenant` live_session with `TenantHook.resolve_tenant`

### Session Keys
- Admin: `_admin_user_token` (JWT)
- Tenant user: `user_token` (JWT), `tenant` (schema string)
- Tenant resolution: `tenant_slug` (slug string)
- Chat: `chat_session_id`

### Existing Account Detail View
- `lib/haul_web/live/admin/account_detail_live.ex`: Has disabled "Impersonate" button with `title="Coming soon (T-023-03)"`.
- Shows company details, status badges, users list.

### Layouts
- **Superadmin layout** (`lib/haul_web/components/layouts/superadmin.html.heex`): Header with "Haul Admin" logo, nav (Dashboard, Accounts), admin email, theme toggle, sign out.
- **Admin layout** (`lib/haul_web/components/layouts/admin.html.heex`): Used for `/app` routes. Sidebar with nav, header with company name.

### Test Infrastructure
- `ConnCase.create_authenticated_context/1`: Creates company + tenant + user + token
- `ConnCase.log_in_user/2`: Sets user_token + tenant in session
- Security tests in `test/haul_web/live/admin/security_test.exs` with `setup_completed_admin/1` helper

## Key Patterns

### Session Coexistence
Admin session (`_admin_user_token`) and tenant session (`user_token`, `tenant`) are independent keys in the same Phoenix session cookie. They don't interfere.

### Route Protection
- Admin routes return 404 (not 403/redirect) for unauthenticated — hides existence
- App routes redirect to `/app/login` for unauthenticated

### Tenant Context Flow
1. TenantResolver plug sets `tenant_slug` in session + assigns
2. TenantHook reads `tenant_slug` from session on LiveView mount
3. AuthHooks reads `tenant` (schema string) from session for JWT verification

### LiveView Sessions
LiveView `live_session` boundaries enforce that sockets cannot cross between `:superadmin`, `:authenticated`, and `:tenant` sessions. Navigating between them causes a full page load with new HTTP request.

## Constraints

1. **LiveView session boundary**: Cannot share socket between `/admin` and `/app`. Impersonation must trigger a full navigation (redirect), which goes through plugs again.
2. **AuthHooks requires real user JWT**: During impersonation, we can't use AuthHooks as-is because there's no valid `user_token` for the impersonated tenant. Need a bypass mechanism.
3. **TenantResolver uses Host header**: During impersonation, the admin is on the admin domain, not the tenant's subdomain. Need to override tenant resolution.
4. **Admin layout shows company name from `current_company`**: Impersonation needs to set this properly.

## Security Observations

1. Impersonation session keys must only be honored when a valid admin session exists (defense against session tampering)
2. Admin routes must be inaccessible during impersonation (no privilege stacking)
3. 1-hour auto-expiry checked on every request (plug + hook level)
4. Structured audit logging for start/end/expiry events
5. Admin logout must clear impersonation state

## Files That Need Changes

- `lib/haul_web/plugs/require_admin.ex` — block /admin during impersonation
- `lib/haul_web/live/admin_auth_hooks.ex` — block /admin LiveViews during impersonation
- `lib/haul_web/live/auth_hooks.ex` — impersonation bypass (skip user JWT, use admin session)
- `lib/haul_web/plugs/tenant_resolver.ex` — check impersonation slug before host-based resolution
- `lib/haul_web/live/tenant_hook.ex` — impersonation-aware tenant resolution
- `lib/haul_web/live/admin/account_detail_live.ex` — enable impersonate button
- `lib/haul_web/components/layouts/superadmin.html.heex` or `admin.html.heex` — banner
- `lib/haul_web/controllers/admin_session_controller.ex` — clear impersonation on logout
- `lib/haul_web/router.ex` — add impersonation start/exit routes
- New: impersonation plug or helper module
- New: impersonation tests
