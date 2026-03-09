# T-013-01 Progress: App Layout

## Completed Steps

### Step 1: Auth Infrastructure ✓
- Created `lib/haul_web/live/auth_hooks.ex` with `on_mount(:require_auth)` hook
- JWT token verification with tenant context for token revocation checks
- User role validation (owner/dispatcher only)
- Company loading from tenant slug
- `attach_hook` for `current_path` tracking via `handle_params`

### Step 2: Session Controller ✓
- Created `lib/haul_web/controllers/app_session_controller.ex`
- `create/2` — stores token + tenant in session, redirects to /app
- `delete/2` — drops session, redirects to /app/login

### Step 3: Login LiveView ✓
- Created `lib/haul_web/live/app/login_live.ex`
- Password login form with email + password
- `phx-trigger-action` pattern for secure session creation via controller POST
- Flash error on invalid credentials
- Flash group display for error messages

### Step 4: Admin Layout ✓
- Created `lib/haul_web/components/layouts/admin.html.heex`
- Sidebar: Dashboard, Content, Bookings, Settings nav links with icons
- Header: company name, user email, theme toggle, sign out link
- Mobile: hamburger toggle, sidebar slide-out with overlay
- Active nav state via `@current_path`
- Added `sidebar_link/1` component in Layouts module

### Step 5: Dashboard LiveView ✓
- Created `lib/haul_web/live/app/dashboard_live.ex`
- Welcome message with user name/email
- Site URL derived from company domain or slug

### Step 6: Router Wiring ✓
- Added `/app/login` public route
- Added `/app/session` POST and DELETE routes
- Added authenticated `live_session :authenticated` scope with `on_mount` hook and admin layout
- Placeholder routes for /app/content, /app/bookings, /app/settings

### Step 7: Test Helpers ✓
- Added `create_authenticated_context/1` to ConnCase
- Added `log_in_user/2` to ConnCase
- Added `cleanup_tenants/0` to ConnCase

### Step 8: Tests ✓
- 9 new tests (7 dashboard, 2 login)
- All 240 tests pass, 0 failures

## Deviations from Plan

- Removed separate `RequireAuth` plug test file — auth is tested through LiveView integration tests
- Used `Ash.Query.filter` instead of `Ash.read_one(filter: ...)` for company lookup due to syntax requirements
- Added `Layouts.flash_group` to login page directly since it doesn't use the admin layout
- Used `phx-trigger-action` pattern instead of JS hook for session creation
