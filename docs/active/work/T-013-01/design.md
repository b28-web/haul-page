# T-013-01 Design: App Layout

## Decision 1: Auth Mechanism

### Option A: Manual session plug (token in session)
- Store AshAuthentication bearer token in session on login
- Plug extracts token, calls `AshAuthentication.subject_to_user/2` with tenant context
- Simple, no new deps

### Option B: Add ash_authentication_phoenix dependency
- Provides `AshAuthentication.Phoenix.Plug`, sign-in LiveView generators, `on_mount` hooks
- Heavier dep, more magic, may conflict with custom tenant resolution

**Decision: Option A.** No new dependency. We already have AshAuthentication configured. We just need a small plug to load user from session token and an `on_mount` hook for LiveView. This keeps the auth flow explicit and avoids pulling in a framework that may not align with our multi-tenant setup.

## Decision 2: Auth Flow Architecture

### Login
1. GET `/app/login` → `AppLoginLive` (LiveView with password form)
2. Form submits email + password → call `Ash.read` with password strategy sign-in action
3. On success: store user token in session, redirect to `/app`
4. On failure: flash error, re-render form

### Session Management
- Store bearer token string in session under key `:user_token`
- `RequireAuth` plug (for dead views) and `on_mount :require_auth` (for LiveView) both:
  1. Read `:user_token` from session
  2. Load user via `AshAuthentication.subject_to_user/2` using tenant from conn/session
  3. Assign `:current_user` and `:current_company`
  4. Redirect to `/app/login` if no valid user or wrong role

### Logout
- DELETE `/app/logout` → clears session, redirects to `/app/login`

## Decision 3: Layout Architecture

### Option A: Separate `admin.html.heex` layout template
- New template in `layouts/` directory, auto-embedded by `Layouts` module
- Clean separation from public `app/1` layout

### Option B: Replace existing `app/1` inline component
- The current `app/1` is Phoenix scaffold boilerplate — replace it entirely

**Decision: Option A + B hybrid.** Create `admin.html.heex` as the app shell layout template. The existing inline `app/1` in layouts.ex is scaffold boilerplate that should be replaced to serve as the public page wrapper (but that's out of scope — we leave it as-is and use a new `admin` layout for `/app` routes).

Actually, simpler: create `app_layout.html.heex` and define `app_layout/1` in Layouts. The `/app` LiveView scope uses `put_root_layout` with root and the LiveView `layout` option to use `app_layout`. This avoids touching the existing `app/1`.

Wait — even simpler: Phoenix LiveView uses `layout: {Layouts, :app}` by default. We should just replace the current `app/1` boilerplate with our admin shell, since public LiveViews (booking, scan, payment) don't use the app layout anyway — they render directly in root. Let me verify...

Public LiveViews don't specify a layout override, so they use the default `app` layout. Changing `app/1` would affect them. Better to:
1. Keep `app/1` as minimal public wrapper (strip the scaffold links)
2. Create `admin/1` as the authenticated layout
3. `/app` LiveViews explicitly set `layout: {Layouts, :admin}`

**Final decision:** New `admin.html.heex` template + `admin/1` component attributes in Layouts. Public LiveViews continue using `app/1` (cleaned up to be a simple passthrough).

## Decision 4: Sidebar + Mobile Nav

### Desktop
- Fixed sidebar (w-64) on the left with nav links
- Header bar across the top of the content area
- Main content fills remaining space

### Mobile (< md breakpoint)
- Sidebar hidden by default
- Hamburger button in header toggles sidebar visibility
- Overlay/slide-out pattern using Tailwind + Alpine-style JS (but we use Phoenix.LiveView.JS)
- Click outside or nav link click closes sidebar

### Nav Items
- Dashboard (`/app`) — hero-home icon
- Content (`/app/content`) — hero-document-text icon (placeholder, links but no page yet)
- Bookings (`/app/bookings`) — hero-calendar icon (placeholder)
- Settings (`/app/settings`) — hero-cog-6-tooth icon (placeholder)

Active state: highlight current nav item based on `@current_path` or socket assigns.

## Decision 5: Dashboard Page

Simple `DashboardLive` at `/app`:
- Welcome message: "Welcome, {user.name || user.email}."
- Site URL: "Your site is live at {url}." where url is derived from company domain or slug
- No data/charts/widgets — just the welcome message per AC

## Decision 6: Login Approach

Since AshAuthentication password strategy is configured, we call the sign-in action directly:
```elixir
Ash.read(User, action: :sign_in_with_password, context: %{token: %{password: password, email: email}})
```

Actually, AshAuthentication sign-in works through `AshAuthentication.Info.strategy/2` and the strategy's `action` function. The standard approach:
1. Get the password strategy: `AshAuthentication.Info.strategy!(User, :password)`
2. Call `AshAuthentication.Strategy.action(strategy, :sign_in, %{"email" => email, "password" => password})`

This returns `{:ok, user_with_token}` or `{:error, ...}`. The user struct will have `__metadata__.token` set.

For the session: store `user.__metadata__.token` in session. To restore: use `AshAuthentication.TokenResource` to verify, then load user.

## Rejected Approaches

- **ash_authentication_phoenix**: Too heavy, custom tenant resolution conflicts
- **Plug.BasicAuth**: Not suitable for a real app UI
- **Guardian/Pow**: External auth libs when we already have AshAuthentication
- **Server-rendered login (non-LiveView)**: LiveView login is simpler, stays in the same framework
