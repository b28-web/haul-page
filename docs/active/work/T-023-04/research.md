# T-023-04 Research: Superadmin Browser QA

## What exists

### Admin panel — full implementation (T-023-01, T-023-02)

**Authentication flow:**
- `Admin.LoginLive` — email + password form → triggers form POST to `AdminSessionController.create`
- JWT token stored in session as `_admin_user_token`
- `RequireAdmin` plug verifies JWT + `setup_completed: true`, returns 404 if unauthorized
- `AdminAuthHooks.on_mount(:require_admin)` — same check for LiveView, blocks during impersonation

**LiveViews:**
- `Admin.DashboardLive` (`/admin`) — welcome message, admin email
- `Admin.AccountsLive` (`/admin/accounts`) — table of companies with search/sort, status indicators
- `Admin.AccountDetailLive` (`/admin/accounts/:slug`) — company details, users table, impersonate button

**Layout:**
- `superadmin.html.heex` — minimal header: "Haul Admin", nav (Dashboard, Accounts), admin email, sign out

### Impersonation (T-023-03)

**Module:** `HaulWeb.Impersonation` — session key management, expiry (1h), audit logging

**Flow:**
1. POST `/admin/impersonate/:slug` → sets session keys → redirects to `/app`
2. `AuthHooks.on_mount(:require_auth)` detects impersonation → bypasses user auth, sets company context
3. Admin layout shows amber banner: "Viewing as {company} ({slug}) — N min remaining"
4. POST `/admin/exit-impersonation` → clears keys → redirects to `/admin/accounts`

**Security:**
- `/admin` returns 404 during impersonation (RequireAdmin blocks, AdminAuthHooks redirects)
- Auto-expiry at 1 hour (checked by TenantResolver + AuthHooks)
- Tenant schema validated before impersonation starts
- Audit logging on start/end/expire

### Existing test coverage

**45 admin tests passing** across 4 files:
- `security_test.exs` — unauth returns 404, setup flow, admin lifecycle
- `accounts_live_test.exs` — list, search, sort, status, security
- `account_detail_live_test.exs` — details, users, impersonate button, security
- `impersonation_test.exs` — helper funcs, start/exit, audit logs, privilege stacking, expiry

### Browser QA test pattern

All existing QA tests use **Phoenix.LiveViewTest** (not actual Playwright):
- `use HaulWeb.ConnCase, async: false`
- `import Phoenix.LiveViewTest`
- Mount with `live(conn, "/path")`, interact with `render_click/3`, `form/3`, `render_submit/1`
- Assertions via `assert html =~ "text"`
- Setup creates test data, `on_exit` cleanup for tenants
- See `proxy_qa_test.exs`, `billing_qa_test.exs`, `domain_qa_test.exs` for patterns

### Test helpers

From `conn_case.ex`:
- `create_admin_session()` — creates admin with password, returns `%{admin, token}`
- `log_in_admin(conn, %{token})` — sets admin session
- `create_authenticated_context(attrs)` — creates company + provisions tenant + registers user
- `cleanup_tenants()` — drops all `tenant_*` schemas

### Router structure

```
# Public (no auth)
POST /admin/session       → AdminSessionController.create
DELETE /admin/session      → AdminSessionController.delete
POST /admin/exit-impersonation → AdminSessionController.exit_impersonation

# Protected (RequireAdmin)
live /admin               → Admin.DashboardLive
live /admin/accounts      → Admin.AccountsLive
live /admin/accounts/:slug → Admin.AccountDetailLive
POST /admin/impersonate/:slug → AdminSessionController.impersonate
```

## Acceptance criteria mapping

| Criterion | What to test | How |
|-----------|-------------|-----|
| Login → dashboard renders | Admin login flow, `/admin` mounts | LiveViewTest: `live(admin_conn, ~p"/admin")` |
| Accounts table | `/admin/accounts` shows companies | LiveViewTest: assert company names |
| Account detail | Click into detail, info + users | LiveViewTest: `live(admin_conn, ~p"/admin/accounts/slug")` |
| Impersonate → /app + banner | POST impersonate, verify redirect + banner | ConnTest: post + follow redirect, check banner text |
| Tenant content matches | /app shows impersonated company content | LiveViewTest: mount /app with impersonation session |
| /admin returns 404 while impersonating | Privilege stacking blocked | ConnTest: get /admin with impersonation session |
| Exit → /admin/accounts, no banner | POST exit, verify redirect + clean state | ConnTest: post exit + follow redirect |
| Regular user → /admin 404 | Non-admin access blocked | ConnTest: get with user session |
| Direct slug access as user → 404 | Non-admin account detail blocked | ConnTest: get detail with user session |

## Constraints

- QA test must be `async: false` (uses shared DB state for tenant provisioning)
- Need `on_exit` cleanup for provisioned tenant schemas
- Impersonation banner is in `admin.html.heex` (the /app layout), not the superadmin layout
- Testing the full impersonation flow requires combining conn-level (POST routes) and LiveView tests
- The impersonation redirect chain: POST → redirect 302 → GET /app → LiveView mount — LiveViewTest can't follow cross-type redirects, so we test pieces separately
