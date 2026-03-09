# T-023-02 Plan: Accounts List

## Step 1: Add Routes
- Add `/admin/accounts` and `/admin/accounts/:slug` to router in `:superadmin` live_session
- Create minimal stub LiveViews that just render a heading
- Verify routes work with admin session (manual smoke check via test)

## Step 2: Accounts List LiveView
- Implement `AccountsLive` mount: load companies, batch tenant status check, SiteConfig checks
- Implement render: search input, sortable table with columns (slug, name, plan, domain, created, status)
- Implement `handle_event` for search (filter) and sort (toggle)
- Status indicators as colored badges: green/red dots or checkmarks

## Step 3: Account Detail LiveView
- Implement `AccountDetailLive` mount: load company by slug param, load users + status
- Handle not-found case: redirect to `/admin/accounts` with error flash
- Render: company attributes (definition list), users table, status badges
- Add disabled "Impersonate" button (placeholder for T-023-03)

## Step 4: Layout Navigation
- Update `superadmin.html.heex` to add nav links (Dashboard, Accounts)
- Active state based on request_path or assigns

## Step 5: Tests — Accounts List
- Test file: `test/haul_web/live/admin/accounts_live_test.exs`
- Setup: create admin user + session, create 2-3 companies with tenants
- Tests:
  - Renders company table with correct data
  - Search filters companies by name/slug
  - Sort toggles work (name asc/desc, date asc/desc)
  - Status indicators show correctly
  - Security: unauthenticated → 404
  - Security: tenant user session → 404

## Step 6: Tests — Account Detail
- Test file: `test/haul_web/live/admin/account_detail_live_test.exs`
- Setup: create admin + company + tenant + users
- Tests:
  - Renders company attributes
  - Renders users table
  - Invalid slug → redirect with flash
  - Security: unauthenticated → 404

## Step 7: Full Suite + Review
- Run `mix test` for full suite
- Write review.md

## Testing Strategy
- Targeted tests after each step: `mix test test/haul_web/live/admin/`
- Full suite before review
- Security tests: reuse patterns from security_test.exs (init_test_session with invalid/no token)
