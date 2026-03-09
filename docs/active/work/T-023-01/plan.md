# T-023-01 Plan: Superadmin Auth

## Step 1: Admin Domain + Resources

Create the Ash domain and resources:
1. `lib/haul/admin.ex` — domain with AdminUser, AdminToken
2. `lib/haul/admin/admin_token.ex` — token resource, public schema, no multitenancy
3. `lib/haul/admin/admin_user.ex` — resource with AshAuthentication, password strategy, custom actions
4. Register domain in Ash config if needed

**Verify:** `mix compile` succeeds

## Step 2: Migration

Generate migration for admin_users and admin_tokens tables:
1. Run `mix ash_postgres.generate_migrations --name create_admin_users`
2. Verify migration creates tables in public schema (not tenant-scoped)
3. Run `mix ecto.migrate`

**Verify:** Tables exist in database

## Step 3: Bootstrap Module

Create `lib/haul/admin/bootstrap.ex`:
1. `ensure_admin!/0` — reads ADMIN_EMAIL, creates AdminUser with setup token, logs URL
2. Token generation: `:crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)`
3. Token storage: `:crypto.hash(:sha256, raw_token)` stored as `setup_token_hash`
4. Add call in `lib/haul/application.ex` after Repo start

**Verify:** Unit test for bootstrap logic

## Step 4: Router + Pipeline

Update `lib/haul_web/router.ex`:
1. Add `:admin_browser` pipeline (browser without TenantResolver/EnsureChatSession)
2. Add `/admin` scope with public routes (setup, login, session)
3. Add authenticated live_session with `:superadmin` layout

**Verify:** `mix compile` succeeds, routes visible in `mix phx.routes`

## Step 5: Admin Session Controller

Create `lib/haul_web/controllers/admin_session_controller.ex`:
1. `create` — verify JWT, store `_admin_user_token` in session
2. `delete` — drop session, redirect to `/admin/login`

**Verify:** Unit test

## Step 6: Admin Auth Hooks

Create `lib/haul_web/live/admin_auth_hooks.ex`:
1. `on_mount(:require_admin, ...)` — load AdminUser from session
2. Return 404 (not redirect) on failure

**Verify:** Unit test

## Step 7: Setup LiveView

Create `lib/haul_web/live/admin/setup_live.ex`:
1. Mount: validate token hash against AdminUser with `setup_completed: false`
2. Render: password + confirmation form
3. Handle submit: validate password, hash, update AdminUser, redirect to login
4. Return 404 for invalid/used tokens

**Verify:** Integration test — full setup flow

## Step 8: Login LiveView

Create `lib/haul_web/live/admin/login_live.ex`:
1. Mount: initialize form
2. Handle login: call `sign_in_with_password`, store token in hidden form
3. Trigger submit to AdminSessionController

**Verify:** Integration test — login flow

## Step 9: Dashboard LiveView + Layout

Create placeholder:
1. `lib/haul_web/live/admin/dashboard_live.ex` — simple "Superadmin Dashboard" page
2. `lib/haul_web/components/layouts/superadmin.html.heex` — minimal layout with sign-out

**Verify:** Authenticated access works end-to-end

## Step 10: Security Tests

Create `test/haul_web/live/admin/security_test.exs`:
1. Unauthenticated `/admin` returns 404
2. Tenant user session does not grant `/admin` access
3. Setup link works exactly once
4. Invalid/random setup token returns 404
5. AdminUser with `setup_completed: true` cannot use setup link
6. After setup, login works with correct password
7. Admin session does not grant `/app` access

**Verify:** All security tests pass

## Step 11: Full Suite

Run `mix test` to verify no regressions.

## Testing Strategy

| Test file | What it covers |
|-----------|---------------|
| `test/haul/admin/admin_user_test.exs` | Resource creation, password hashing, sign-in |
| `test/haul/admin/bootstrap_test.exs` | env var bootstrap, idempotency, token generation |
| `test/haul_web/live/admin/setup_live_test.exs` | Setup flow, token validation, password setting |
| `test/haul_web/live/admin/login_live_test.exs` | Login form, authentication, session |
| `test/haul_web/live/admin/security_test.exs` | All acceptance criteria security tests |
