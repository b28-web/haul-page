# T-013-01 Review: App Layout

## Summary

Implemented the authenticated `/app` layout shell with sidebar navigation, header with operator info, mobile-responsive design, login page, and empty dashboard.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/live/auth_hooks.ex` | `on_mount(:require_auth)` hook — JWT verify, user load, role check, current_path tracking |
| `lib/haul_web/plugs/require_auth.ex` | Plug version of auth check (for controller routes if needed) |
| `lib/haul_web/controllers/app_session_controller.ex` | Session create (login) and delete (logout) |
| `lib/haul_web/live/app/login_live.ex` | Password login form with phx-trigger-action pattern |
| `lib/haul_web/live/app/dashboard_live.ex` | Welcome page with user greeting and site URL |
| `lib/haul_web/components/layouts/admin.html.heex` | Admin shell: sidebar + header + main content |
| `test/haul_web/live/app/dashboard_live_test.exs` | 7 tests: auth redirect, owner/dispatcher access, crew reject, UI assertions |
| `test/haul_web/live/app/login_live_test.exs` | 2 tests: renders form, invalid credentials error |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added `/app/login`, `/app/session`, and authenticated `/app` live_session scope |
| `lib/haul_web/components/layouts.ex` | Added `sidebar_link/1` component |
| `test/support/conn_case.ex` | Added `create_authenticated_context/1`, `log_in_user/2`, `cleanup_tenants/0` helpers |

## Test Coverage

- **9 new tests**, all passing
- **240 total tests**, 0 failures (no regressions)
- Covered: unauthenticated redirect, owner access, dispatcher access, crew role rejection, company name display, sidebar nav presence, sign out link, login form render, invalid credentials error
- Not covered: successful login flow end-to-end (requires browser/controller integration), logout flow, mobile sidebar toggle (JS-only)

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `/app` route scope in router, requires authenticated owner/dispatcher | ✓ |
| Sidebar: Dashboard, Content, Bookings, Settings nav links | ✓ |
| Header: operator business name, user email, logout | ✓ |
| Mobile: hamburger menu, slide-out sidebar | ✓ (JS toggle via LiveView.JS) |
| Redirects to `/app/login` if not authenticated | ✓ |
| Uses existing AshAuthentication session (password) | ✓ |
| Dark theme consistent with public pages | ✓ |
| Empty dashboard page with welcome message | ✓ |

## Architecture Decisions

1. **No ash_authentication_phoenix dep** — built auth manually with JWT verify + on_mount hook. Keeps it simple and explicit.
2. **phx-trigger-action pattern** — LoginLive validates credentials via LiveView event, then triggers a real form POST to the session controller. Secure (token never in URL), standard Phoenix pattern.
3. **Separate admin layout** — `admin.html.heex` template, doesn't touch existing `app/1` layout used by public pages.
4. **attach_hook for current_path** — tracks URI in `handle_params` to highlight active sidebar link, avoids per-LiveView boilerplate.

## Open Concerns

1. **Magic link sender is stubbed** — password login works, but magic link emails aren't implemented yet. Not blocking.
2. **Token expiry** — JWT tokens have a default lifetime from AshAuthentication. No refresh mechanism built yet. Sessions will expire and user will be redirected to login.
3. **Placeholder routes** — `/app/content`, `/app/bookings`, `/app/settings` all route to DashboardLive as placeholder. Future tickets (T-013-02..05) will replace these.
4. **RequireAuth plug** — created but not currently used in router (auth is handled via on_mount). Available for future controller-based admin routes.
5. **Tenant resolution for login** — LoginLive reads tenant from session (set by TenantResolver plug). If no tenant in session, login won't have tenant context. Works in normal flow (TenantResolver runs in browser pipeline).
