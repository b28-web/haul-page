# T-023-04 Review: Superadmin Browser QA

## Summary

End-to-end QA test for the superadmin panel covering the full flow: login → dashboard → accounts list → account detail → impersonate → verify banner + tenant content → exit → security checks.

## Full test suite result

```
845 tests, 0 failures (1 excluded)
Finished in 109.5 seconds
```

## Files changed

### Created
- `test/haul_web/live/admin/superadmin_qa_test.exs` — 18 QA tests

### Modified
- `lib/haul_web/live/app/dashboard_live.ex` — Fixed crash when `@current_user` is nil during impersonation. Added `:if` guard and impersonation-specific message.

## Test coverage: acceptance criteria

| Criterion | Tests | Status |
|-----------|-------|--------|
| Login → dashboard renders | `admin can access dashboard` | PASS |
| Dashboard shows admin info | `dashboard shows admin email` | PASS |
| Accounts table shows companies | `shows test companies`, `shows company slugs` | PASS |
| Account detail with company info | `shows company info` | PASS |
| Impersonate button present | `shows impersonate button` | PASS |
| Impersonate → /app redirect | `start impersonation redirects to /app` | PASS |
| Impersonation banner visible | `impersonation banner visible with company info` | PASS |
| Tenant content matches impersonated company | `tenant content matches impersonated company` | PASS |
| Exit → /admin/accounts | `exit impersonation returns to admin accounts` | PASS |
| Admin accessible after exit | `/admin/accounts accessible after exit` | PASS |
| /admin 404 while impersonating | 3 privilege stacking tests | PASS |
| Regular user → /admin 404 | `regular user gets 404 on /admin` | PASS |
| Direct slug access as user → 404 | `regular user gets 404 on /admin/accounts/:slug` | PASS |
| Unauthenticated → 404 | 2 unauthenticated tests | PASS |

## Bug found and fixed

**DashboardLive nil user crash:** `@current_user.name || @current_user.email` in the template crashed during impersonation because `AuthHooks` sets `current_user: nil` for admin sessions. Fixed by adding `:if={@current_user}` guard and showing an impersonation-specific message instead.

## Open concerns

- **Acceptance criterion gap:** "Navigate to `/admin/accounts` — accounts table shows test companies" is tested, but clicking through from the dashboard (LiveView navigation) is not separately tested since the existing `accounts_live_test.exs` already covers search/sort/navigation thoroughly.

- **Impersonation banner countdown:** The "N min remaining" is tested as present but not verified for accuracy. Expiry logic is tested in `impersonation_test.exs`.

## No known issues

All 845 tests pass. No regressions introduced.
