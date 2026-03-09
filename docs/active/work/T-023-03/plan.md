# T-023-03 Plan: Impersonation

## Step 1: Create Impersonation Helper Module

Create `lib/haul_web/impersonation.ex` with:
- `active?/1` — checks for `impersonating_slug` key in session map
- `expired?/1` — parses `impersonating_since`, compares to now, returns true if > 3600s
- `remaining_minutes/1` — max(0, 60 - elapsed_minutes)
- `start_session/3` — puts 3 session keys, Logger.info with structured metadata
- `end_session/2` — deletes 3 session keys, Logger.info (reason: :manual or :expired)
- `validate_and_load/1` — validates admin JWT + loads Company from slug, returns tagged tuple
- `check_admin_session/1` — verifies `_admin_user_token` JWT is valid

**Verify**: `mix compile` succeeds

## Step 2: Modify AdminSessionController

Add `impersonate/2`:
- Receives `%{"slug" => slug}` params
- `conn.assigns.current_admin` already set by RequireAdmin plug
- Load Company by slug, 404 if not found
- Check schema exists (provisioned), flash error if not
- Call `Impersonation.start_session(conn, admin, slug)`
- Redirect to `/app`

Add `exit_impersonation/2`:
- Verify admin JWT manually (route is in public scope)
- Call `Impersonation.end_session(conn, :manual)`
- Redirect to `/admin/accounts`

Modify `delete/2`:
- Also delete impersonation keys

**Verify**: `mix compile` succeeds

## Step 3: Add Routes

In authenticated `/admin` scope (line ~93):
- `post "/impersonate/:slug", AdminSessionController, :impersonate`

In public `/admin` scope (line ~82):
- `post "/exit-impersonation", AdminSessionController, :exit_impersonation`

**Verify**: `mix compile` succeeds, `mix phx.routes | grep impersonate` shows routes

## Step 4: Modify RequireAdmin Plug

After successful admin verification, add impersonation block:
- Check `get_session(conn, "impersonating_slug")`
- If present: return 404 (block admin access)
- Also check expiry: if expired, clear keys via Impersonation.end_session, redirect to /admin with flash

**Verify**: `mix compile` succeeds

## Step 5: Modify AdminAuthHooks

After successful admin load in `on_mount(:require_admin)`:
- Check session for `"impersonating_slug"`
- If present: halt + redirect (block LiveView admin access)

**Verify**: `mix compile` succeeds

## Step 6: Modify TenantResolver Plug

At start of `call/2`, before host-based resolution:
- Check session for `"impersonating_slug"` AND valid admin session
- If impersonation active: resolve tenant from slug, set assigns, skip host resolution
- If impersonation expired: clear keys, redirect to /admin with flash

**Verify**: `mix compile` succeeds

## Step 7: Modify TenantHook

In `on_mount(:resolve_tenant)`:
- Check session for `"impersonating_slug"`
- If present: use that slug instead of `tenant_slug`

**Verify**: `mix compile` succeeds

## Step 8: Modify AuthHooks

In `on_mount(:require_auth)`:
- Before normal user auth flow, check for impersonation
- If impersonation active: validate admin JWT, load Company, bypass user auth
- Assign `current_user: nil`, `current_company: company`, `impersonating: true`, `current_admin: admin`
- Assign `impersonating_slug`, `impersonating_remaining` for banner
- If expired: redirect to /admin with flash

**Verify**: `mix compile` succeeds

## Step 9: Add Banner to Admin Layout

In `admin.html.heex`:
- Add conditional banner before header: `<div :if={assigns[:impersonating]}>`
- Fixed top bar, amber/warning color scheme
- Content: "Viewing as {company.name} ({slug}) — {remaining} min remaining"
- Exit form: `<form method="post" action="/admin/exit-impersonation">` with CSRF token
- Push main content down when banner visible

**Verify**: Visual check (manual)

## Step 10: Enable Impersonate Button

In `account_detail_live.ex`:
- Replace disabled button with form: `<form method="post" action={~p"/admin/impersonate/#{@company.slug}"}`
- Add CSRF token
- Only show when `@provisioned` is true
- Keep disabled state when not provisioned

**Verify**: `mix compile` succeeds

## Step 11: Add ConnCase Helper

In `test/support/conn_case.ex`:
- Add `create_admin_session/0` — creates admin, completes setup, returns `%{admin: admin, token: token}`
- Add `log_in_admin/2` — sets `_admin_user_token` in test session

## Step 12: Write Tests

Create `test/haul_web/live/admin/impersonation_test.exs`:

1. **Start impersonation**: Admin POSTs to `/admin/impersonate/:slug` → redirects to `/app`, session has keys
2. **Banner renders**: During impersonation, `/app` shows banner with company name + time remaining
3. **Exit impersonation**: POST to `/admin/exit-impersonation` → clears keys, redirects to `/admin/accounts`
4. **Auto-expiry**: Set `impersonating_since` to 2 hours ago → next request redirects to `/admin`
5. **Privilege stacking blocked**: During impersonation, GET `/admin` returns 404
6. **Tenant user cannot impersonate**: User without admin session sets impersonation keys → ignored
7. **Admin logout clears impersonation**: DELETE `/admin/session` clears all keys
8. **Invalid slug**: POST to `/admin/impersonate/nonexistent` → error flash
9. **Audit log entries**: Capture Logger output, assert structured metadata

**Verify**: `mix test test/haul_web/live/admin/impersonation_test.exs` passes

## Step 13: Full Test Suite

Run `mix test` and verify no regressions. Note result in progress.md.

## Testing Strategy

- Unit: Impersonation helper module functions (active?, expired?, remaining_minutes)
- Integration: Controller actions (start, exit, logout cleanup)
- Security: Privilege stacking, tenant user tampering, expiry enforcement
- LiveView: Banner rendering, AuthHooks bypass
- Cross-cutting: Existing admin security tests still pass
