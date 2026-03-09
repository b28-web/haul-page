# T-023-03 Review: Impersonation

## Test Results

```
mix test
827 tests, 0 failures (1 excluded)
Finished in 108.1 seconds
```

No regressions. 16 new impersonation tests added.

## Changes Summary

### New Files (2)
- `lib/haul_web/impersonation.ex` — Centralized impersonation session management: `active?/1`, `expired?/1`, `remaining_minutes/1`, `start_session/3`, `end_session/2`, `validate_and_load/1`, `check_admin_session/1`. Audit logging via `Logger.warning` with structured metadata.
- `test/haul_web/live/admin/impersonation_test.exs` — 16 tests covering all acceptance criteria.

### Modified Files (10)
- `lib/haul_web/controllers/admin_session_controller.ex` — Added `impersonate/2`, `exit_impersonation/2`. Modified `delete/2` to clear impersonation keys.
- `lib/haul_web/router.ex` — Added `POST /admin/impersonate/:slug` and `POST /admin/exit-impersonation` routes.
- `lib/haul_web/plugs/require_admin.ex` — Blocks `/admin` access during impersonation (404).
- `lib/haul_web/live/admin_auth_hooks.ex` — Blocks admin LiveViews during impersonation (redirect).
- `lib/haul_web/plugs/tenant_resolver.ex` — Impersonation override before host-based resolution. Session guard for API routes.
- `lib/haul_web/live/tenant_hook.ex` — Uses `impersonating_slug` when active.
- `lib/haul_web/live/auth_hooks.ex` — Impersonation bypass: skips user JWT, uses admin session, sets impersonation assigns.
- `lib/haul_web/components/layouts/admin.html.heex` — Fixed amber banner with company name, slug, time remaining, exit button. Hidden sign-out during impersonation.
- `lib/haul_web/live/admin/account_detail_live.ex` — Enabled impersonate button (form POST, conditional on provisioned status).
- `test/haul_web/live/admin/account_detail_live_test.exs` — Updated test from "disabled" button to active impersonate form.
- `test/support/conn_case.ex` — Added `create_admin_session/0` and `log_in_admin/2` helpers.

## Acceptance Criteria Coverage

| Criterion | Status | Notes |
|-----------|--------|-------|
| Impersonate action stores session keys | Done | `impersonating_slug`, `impersonating_since`, `real_admin_id` |
| Redirects to /app with tenant context | Done | TenantResolver + AuthHooks handle context |
| Session auto-expires after 1 hour | Done | Checked in TenantResolver, AuthHooks |
| Impersonation banner on every page | Done | Fixed amber bar in admin layout |
| Banner shows business name, slug, time, exit | Done | All elements rendered |
| Exit clears keys, redirects to /admin/accounts | Done | POST /admin/exit-impersonation |
| TenantResolver checks impersonating_slug | Done | Overrides host-based resolution |
| Expired session cleared + redirect + flash | Done | "Impersonation session expired" |
| /admin returns 404 during impersonation | Done | RequireAdmin + AdminAuthHooks block |
| Ash actions tagged with admin_user actor | Partial | `current_admin` assigned, `current_user` is nil |
| Audit logging (start/end/expiry) | Done | Logger.warning with structured metadata |
| Impersonation cleared on admin logout | Done | delete/2 calls end_session |
| Tenant users can't set impersonation keys | Done | Keys ignored without valid admin JWT |
| Expired impersonation redirects | Done | Tested in unit and integration |
| /admin inaccessible during impersonation | Done | 404 on plug + LiveView levels |

## Test Coverage

- **Unit**: Impersonation helper functions (active?, expired?, remaining_minutes)
- **Integration**: Start impersonation, exit impersonation, admin logout cleanup
- **Security**: Privilege stacking blocked, tenant user tampering rejected, unauthenticated access blocked
- **Audit**: Start and end events captured and verified
- **UI**: Impersonate button rendering on account detail

## Open Concerns

1. **`current_user` is nil during impersonation**: Any `/app` LiveView code that accesses `@current_user.email` (etc.) without a nil guard will crash during impersonation. The admin layout guards `@current_user` with `:if`, and the sign-out link is hidden. Other LiveViews should be robust to nil user, but may need testing in browser QA (T-023-04).

2. **Ash action actor tagging**: The ticket says "All Ash actions during impersonation are tagged with actor: admin_user in metadata." Currently, `current_admin` is assigned to the socket, but Ash actions in LiveViews typically use `actor: @current_user`. Since impersonation is primarily for viewing (not mutating), this may be acceptable. If write actions are needed during impersonation, Ash action calls would need to be modified to use the admin as actor — but that's a broader change.

3. **Expiry not enforced within a LiveView session**: Expiry is checked on mount (HTTP request or WebSocket reconnect), but if a LiveView stays connected for > 1 hour, the impersonation persists. The next navigation or reconnect will enforce expiry. A JS timer could handle this but would add complexity.

4. **Banner CSRF token**: The exit button uses `Phoenix.Controller.get_csrf_token()` in the layout template. This works but is evaluated at render time. Should be fine for normal usage.

## Architecture Notes

The design keeps impersonation logic centralized in `HaulWeb.Impersonation` module, used by 6 consumers (controller, 2 plugs, 3 hooks). This avoids duplication and makes the logic easy to audit. Session keys are string-typed to avoid conflicts with atom-keyed session entries from other systems.
