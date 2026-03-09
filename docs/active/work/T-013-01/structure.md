# T-013-01 Structure: App Layout

## New Files

### `lib/haul_web/plugs/require_auth.ex`
- Plug that loads user from session token
- Checks role is :owner or :dispatcher
- Redirects to `/app/login` if not authenticated or wrong role
- Sets `conn.assigns.current_user`

### `lib/haul_web/live/auth_hooks.ex`
- Module with `on_mount(:require_auth, ...)` callback
- Reads user token from session (via connect_params or session)
- Loads user via AshAuthentication token verification
- Assigns `:current_user` and `:current_company` to socket
- Redirects to `/app/login` on failure

### `lib/haul_web/components/layouts/admin.html.heex`
- Admin layout template: sidebar + header + main content area
- Sidebar: nav links with icons, active state
- Header: company name, user email, hamburger toggle, logout link
- Mobile: hidden sidebar, JS toggle
- Dark theme, Oswald headings, Source Sans 3 body

### `lib/haul_web/live/app/dashboard_live.ex`
- Mount: assigns current_user, current_company (from socket assigns via on_mount)
- Render: welcome message with user name, site URL from company

### `lib/haul_web/live/app/login_live.ex`
- Password login form (email + password fields)
- `handle_event("login", ...)` calls AshAuthentication password sign-in
- On success: put token in session, redirect to `/app`
- On failure: flash error

### `lib/haul_web/controllers/app_session_controller.ex`
- `create/2` — called by LoginLive to set session token (LiveView can't set session directly, need a controller redirect)
- `delete/2` — logout: clear session, redirect to `/app/login`

### `test/haul_web/live/app/dashboard_live_test.exs`
- Test: unauthenticated redirects to /app/login
- Test: authenticated owner sees welcome message
- Test: crew role is rejected

### `test/haul_web/live/app/login_live_test.exs`
- Test: login page renders
- Test: valid credentials redirect to /app
- Test: invalid credentials show error

### `test/haul_web/plugs/require_auth_test.exs`
- Test: no token redirects
- Test: valid token assigns user
- Test: invalid role redirects

## Modified Files

### `lib/haul_web/router.ex`
- Add `/app/login` route (public, browser pipeline)
- Add `/app` scope with `:browser` pipeline + `require_auth` on_mount
- Add session controller routes for login POST and logout DELETE

### `lib/haul_web/components/layouts.ex`
- Add `admin/1` component attrs (flash, current_user, current_company, current_path)
- Template auto-embedded from `admin.html.heex`

### `test/support/conn_case.ex`
- Add `log_in_user/2` helper that puts auth token in session

## Module Boundaries

```
Router
  ├── /app/login (LoginLive) — public, browser pipeline
  ├── /app/session (AppSessionController) — POST create, DELETE delete
  └── /app/* (live_session :authenticated)
       ├── on_mount: AuthHooks.require_auth
       └── /app → DashboardLive
           /app/content → (future)
           /app/bookings → (future)
           /app/settings → (future)

AuthHooks.require_auth (on_mount)
  ├── reads :user_token from session
  ├── verifies token, loads User with tenant context
  ├── assigns :current_user, :current_company
  └── redirects to /app/login on failure

AppSessionController
  ├── create: stores token in session, redirects to /app
  └── delete: clears session, redirects to /app/login
```

## Ordering
1. RequireAuth plug + AuthHooks module (auth infrastructure)
2. AppSessionController (session management)
3. LoginLive (login page)
4. admin.html.heex layout (shell UI)
5. DashboardLive (landing page)
6. Router wiring
7. Tests
