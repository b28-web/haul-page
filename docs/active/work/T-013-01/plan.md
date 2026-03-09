# T-013-01 Plan: App Layout

## Step 1: Auth Infrastructure

Create `lib/haul_web/live/auth_hooks.ex`:
- `on_mount(:require_auth, ...)` — load user from session token, verify role, assign to socket
- `on_mount(:load_user, ...)` — optional: load user without requiring (for login page to detect already-logged-in)

Create `lib/haul_web/plugs/require_auth.ex`:
- Plug for dead views (controllers) — same logic as on_mount but for conn

**Verify:** Module compiles, `mix compile` passes.

## Step 2: Session Controller

Create `lib/haul_web/controllers/app_session_controller.ex`:
- `create(conn, %{"token" => token})` — put token in session, redirect to `/app`
- `delete(conn, _params)` — clear session, redirect to `/app/login`

**Verify:** Module compiles.

## Step 3: Login LiveView

Create `lib/haul_web/live/app/login_live.ex`:
- Simple form: email + password
- `handle_event("login", params, socket)`:
  1. Get password strategy from User
  2. Call `AshAuthentication.Strategy.action(strategy, :sign_in, params)` with tenant
  3. On success: redirect to session controller create with token
  4. On failure: put flash error

**Verify:** Module compiles.

## Step 4: Admin Layout

Create `lib/haul_web/components/layouts/admin.html.heex`:
- Sidebar (desktop visible, mobile hidden)
- Header with company name, user info, hamburger, logout
- Main content area with flash group
- Mobile sidebar toggle via `JS.toggle` on sidebar element
- Dark theme classes using CSS custom properties

Update `lib/haul_web/components/layouts.ex`:
- Add `admin/1` component with attrs: flash, current_user, current_company, current_path

**Verify:** Template compiles, no warnings.

## Step 5: Dashboard LiveView

Create `lib/haul_web/live/app/dashboard_live.ex`:
- Uses `admin` layout
- Renders welcome message with user name and site URL
- Site URL derived from company: `{slug}.haulpage.com` or custom domain

**Verify:** Module compiles.

## Step 6: Router Wiring

Update `lib/haul_web/router.ex`:
- Add public route: `live "/app/login", AppLoginLive`
- Add session routes: `post "/app/session", AppSessionController, :create` and `delete "/app/session", AppSessionController, :delete`
- Add authenticated live_session scope:
  ```
  live_session :authenticated, on_mount: [{HaulWeb.AuthHooks, :require_auth}], layout: {HaulWeb.Layouts, :admin} do
    live "/app", App.DashboardLive
  end
  ```

**Verify:** `mix compile` passes, router compiles.

## Step 7: Test Helpers

Update `test/support/conn_case.ex`:
- Add `register_and_log_in_user/1` helper — creates company, provisions tenant, creates user, puts token in session
- Add `create_user_and_token/1` helper — returns {user, token, tenant}

**Verify:** Helpers compile.

## Step 8: Tests

Create `test/haul_web/live/app/dashboard_live_test.exs`:
- Unauthenticated → redirects to /app/login
- Authenticated owner → sees welcome message
- Authenticated dispatcher → sees welcome message
- Crew role → redirected (forbidden)

Create `test/haul_web/live/app/login_live_test.exs`:
- Login page renders form
- Valid credentials → redirects
- Invalid credentials → error flash

Create `test/haul_web/plugs/require_auth_test.exs`:
- No token → redirect
- Valid token → assigns user
- Invalid role → redirect

**Verify:** `mix test` — all new tests pass, no regressions.

## Testing Strategy
- Unit: RequireAuth plug (conn-level)
- Integration: LiveView tests for dashboard (authenticated mount) and login (form interaction)
- Auth flow: end-to-end login → session → dashboard access
- Negative: unauthorized access, wrong role, expired token
