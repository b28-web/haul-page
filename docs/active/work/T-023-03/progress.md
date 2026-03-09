# T-023-03 Progress: Impersonation

## Completed Steps

1. **Impersonation helper module** — Created `lib/haul_web/impersonation.ex` with session management, expiry logic, validation, and audit logging.

2. **AdminSessionController** — Added `impersonate/2` and `exit_impersonation/2` actions. Modified `delete/2` to clear impersonation keys on logout.

3. **Router** — Added `POST /admin/impersonate/:slug` (authenticated) and `POST /admin/exit-impersonation` (public scope, manual admin validation).

4. **RequireAdmin plug** — Added impersonation block: returns 404 when `impersonating_slug` is in session (prevents privilege stacking).

5. **AdminAuthHooks** — Added impersonation block for LiveView: halts and redirects when impersonating.

6. **TenantResolver plug** — Added impersonation override: resolves tenant from `impersonating_slug` instead of hostname. Handles expiry. Guards against missing session (API routes).

7. **TenantHook** — Added impersonation awareness: uses `impersonating_slug` over `tenant_slug` when active.

8. **AuthHooks** — Added impersonation bypass: validates admin JWT, sets `current_user: nil`, `current_company`, `impersonating: true`, `current_admin` assigns. Handles expiry redirect.

9. **Admin layout banner** — Added fixed amber banner at top of `admin.html.heex` showing company name, slug, time remaining, and exit button. Hidden sign-out link during impersonation.

10. **Account detail impersonate button** — Replaced disabled placeholder with active form button. Disabled when tenant not provisioned.

11. **ConnCase helpers** — Added `create_admin_session/0` and `log_in_admin/2` for test convenience.

12. **Tests** — 16 tests covering start, exit, audit logging, privilege stacking, tenant user tampering, admin logout cleanup, expiry, and button rendering.

13. **Full suite** — 827 tests, 0 failures (1 excluded).

## Deviations from Plan

- Used `Logger.warning` instead of `Logger.info` for audit logging — test config sets logger level to `:warning`, and impersonation events are security-relevant enough to warrant warning level.
- Included slug and admin info directly in log message text (not just metadata) for visibility in default log formatter.
- `exit_impersonation` route placed in public `/admin` scope because RequireAdmin blocks during impersonation. Manual admin JWT validation in the action.
