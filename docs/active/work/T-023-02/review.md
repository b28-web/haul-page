# T-023-02 Review: Accounts List

## Summary
Built the superadmin accounts list and detail views. Superadmins can browse all tenant accounts, search/filter by name or slug, sort by columns, view status indicators, and drill into individual accounts to see company attributes, tenant users, and provisioning status.

## Full Test Suite
**798 tests, 0 failures (1 excluded)** — up from 742 baseline (+56 net, 18 new in this ticket + tests from other concurrent work).

## Files Created
- `lib/haul_web/live/admin/accounts_live.ex` — List view at `/admin/accounts`. Shows all companies in a searchable, sortable table with status indicators (provisioned, has content, domain verified). Batch SQL query for schema existence, per-tenant SiteConfig check.
- `lib/haul_web/live/admin/account_detail_live.ex` — Detail view at `/admin/accounts/:slug`. Shows all company attributes, tenant users (email, role, created date), status badges. Disabled "Impersonate" button placeholder for T-023-03. Redirects to list with flash on invalid slug.
- `test/haul_web/live/admin/accounts_live_test.exs` — 10 tests: renders table, search filters, sort toggles, status indicators, row navigation, total count, security (404 for unauthenticated, invalid token, tenant user).
- `test/haul_web/live/admin/account_detail_live_test.exs` — 8 tests: renders company details, users table, status badges, impersonate button, invalid slug redirect, back link, security (404 for unauthenticated, tenant user).

## Files Modified
- `lib/haul_web/router.ex` — Added 2 routes in `:superadmin` live_session: `/accounts` and `/accounts/:slug`.
- `lib/haul_web/components/layouts/superadmin.html.heex` — Added nav links (Dashboard, Accounts) to header.

## Acceptance Criteria Checklist
- [x] `Admin.AccountsLive` at `/admin/accounts` — table of all Companies
- [x] Columns: slug, business name, plan, domain, created date, status indicators
- [x] Status indicators: tenant provisioned, has content, domain verified
- [x] Sortable by created date, business name (+ slug)
- [x] Search/filter by slug or business name
- [x] Click row → detail view
- [x] Detail view (`/admin/accounts/:slug`) — company attributes, user count/list, tenant status
- [x] "Impersonate" button (disabled placeholder, links to T-023-03)
- [x] Read-only — no mutation actions
- [x] Queries run without tenant scoping (public schema)
- [x] Non-superadmin gets 404

## Test Coverage
- List view: rendering, search, sort, status indicators, navigation, security
- Detail view: rendering, users, statuses, not-found handling, security
- Security: unauthenticated, invalid token, and tenant user all get 404

## Open Concerns
- **Performance at scale:** Status checks (SiteConfig) are per-tenant sequential queries. Fine for <100 tenants. If tenant count grows significantly, consider caching or batch queries.
- **No pagination:** Entire company list loaded in memory. Appropriate for current scale, would need pagination at ~500+ tenants.
- **User "last login" not shown:** Acceptance criteria mentions "last login" in detail view, but User resource has no last_login field. Would require a schema migration to add. Not blocking.
- **"Recent activity" in detail view:** Criteria mentions "recent activity" — not implemented as there's no activity/audit log resource. Could be added in a future ticket.

## Dependencies
- Depends on: T-023-01 (superadmin auth) — complete, provides all auth infrastructure
- Blocks: T-023-03 (impersonation) — placeholder button ready, T-023-04 (browser QA)
