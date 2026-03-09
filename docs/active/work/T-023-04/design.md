# T-023-04 Design: Superadmin Browser QA

## Approach

**Single test file** — `test/haul_web/live/admin/superadmin_qa_test.exs`

This follows the established QA test pattern: LiveView integration tests using Phoenix.LiveViewTest, organized by describe blocks for each acceptance criterion. Not actual Playwright browser automation (consistent with all other `*_qa_test.exs` files).

## Options considered

### A: Single comprehensive QA test file (chosen)
- One file covering the full superadmin flow: login, accounts, detail, impersonation, exit, security
- Shared setup block creates admin + tenant with content
- Matches the pattern of `proxy_qa_test.exs` — single file per feature area

### B: Multiple focused QA test files
- Separate files for login flow, impersonation flow, security
- More granular but duplicates setup code
- Rejected: existing QA tests are single-file-per-ticket

### C: Extend existing tests with QA tags
- Add `@tag :qa` to existing admin tests
- Rejected: QA tests are end-to-end flow tests, not unit tests. Different setup, different assertions.

## Decision: Option A

One test file with these describe blocks:
1. **Superadmin login → dashboard** — complete auth flow
2. **Accounts list** — table with test companies
3. **Account detail** — company info, users, impersonate button
4. **Impersonation flow** — start → /app with banner → tenant content → exit
5. **Security: privilege stacking** — /admin blocked during impersonation
6. **Security: regular user** — /admin returns 404, direct slug access returns 404

## Key design decisions

**Setup strategy:** Single `setup` block creates:
- Admin user (via `create_admin_session()`)
- Two companies with provisioned tenants and content (to verify isolation)
- One tenant user (for security tests)
- `on_exit` cleanup for tenant schemas

**Testing impersonation banner:** Can't follow the full redirect chain (POST → 302 → LiveView mount) in one step. Instead:
1. Test POST redirect separately (verify session keys set, redirect to /app)
2. Mount /app LiveView with impersonation session pre-set (verify banner renders)
3. Test exit POST separately (verify session keys cleared, redirect to /admin/accounts)

**Tenant content verification:** Create SiteConfig for the test company, then mount /app with impersonation session and verify the company name appears (from `@current_company.name` in the layout).

**404 vs redirect behavior:**
- `RequireAdmin` plug returns literal 404 for non-admin users (conn-level test)
- `AdminAuthHooks` redirects to "/" for LiveView mounts (can't test via LiveViewTest since it goes through the plug first)
- Test via `get(conn, ~p"/admin")` which hits the plug

## What NOT to test

- Admin setup/bootstrap flow (covered by `security_test.exs`)
- Impersonation helper functions (covered by `impersonation_test.exs`)
- Audit logging (covered by `impersonation_test.exs`)
- Search/sort on accounts list (covered by `accounts_live_test.exs`)
- Impersonation expiry (covered by `impersonation_test.exs`)

The QA test focuses on **end-to-end user flows**, not edge cases or unit behavior.
