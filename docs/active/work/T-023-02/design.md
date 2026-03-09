# T-023-02 Design: Accounts List

## Problem
Superadmin needs a read-only view of all tenant accounts — list with search/sort, detail view per account with user counts and status indicators.

## Approach: Single LiveView with Two Modes

### Option A: Two Separate LiveViews (AccountsLive + AccountDetailLive)
- Pros: Simple routing, each module focused
- Cons: More files, duplicated setup logic

### Option B: Single LiveView with Conditional Rendering
- Pros: Shared state, less code
- Cons: One module doing two things, harder to test

### Option C: Two LiveViews with Shared Query Module
- Pros: Clean separation, reusable query logic, testable
- Cons: Extra module

**Decision: Option A — Two separate LiveViews.**
Simplest, matches the existing pattern (each route = one LiveView). No shared state needed between list and detail. The query logic is simple enough to inline.

## Data Loading Strategy

### Company List
- Use `Ash.read!(Company)` — default `:read` action, no tenant context needed
- Sort in Elixir (small dataset, <100 companies expected) rather than adding Ash sort actions
- Filter in Elixir with `String.contains?/2` on slug/name
- No pagination needed at this scale

### Status Indicators
Three indicators per company:

1. **Tenant provisioned**: Check if PostgreSQL schema `tenant_{slug}` exists
   - SQL: `SELECT 1 FROM information_schema.schemata WHERE schema_name = $1`
   - Cache in assigns on mount, not on every render

2. **Has content**: Check if SiteConfig exists in tenant schema
   - `Ash.read(SiteConfig, tenant: "tenant_#{slug}")` — non-empty means has content
   - Only check for provisioned tenants

3. **Domain verified**: Pure attribute check — `company.domain_status in [:verified, :active]`
   - No extra query needed

### User Count (Detail View Only)
- Only fetch on detail view, not list (too expensive)
- `Ash.read!(User, tenant: "tenant_#{slug}")` then `length/1`
- Show users table in detail view

### Performance Consideration
Checking schema existence and SiteConfig for every company on list load could be slow with many tenants. At current scale (<100 companies), sequential queries are fine. If it becomes an issue, batch SQL query for all schemas in one shot:
```sql
SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'
```
Then match against company slugs. **Start with batch approach** since it's barely more complex.

## Search and Sort

### Search
- Client-side filter via `phx-change` on a text input
- Filter companies where slug or name contains search term (case-insensitive)
- No debounce needed — small dataset

### Sort
- Two sortable columns: business name, created date
- Toggle asc/desc on click
- Default: created date descending (newest first)

## Detail View (`/admin/accounts/:slug`)

### Data Loading
- `Ash.read!(Company) |> Enum.find(&(&1.slug == slug))` or add a `:by_slug` read action
- If not found, redirect to accounts list with flash
- Load users from tenant schema
- Load SiteConfig from tenant schema
- Check schema existence

### Content
- Company attributes (all fields in a definition list)
- Users table (email, role, created date)
- Status indicators (same as list view)
- "Impersonate" button — disabled/placeholder linking to T-023-03

## Layout Navigation
- Add nav links to superadmin layout header: Dashboard, Accounts
- Simple horizontal nav, highlight current page

## Security
- Existing RequireAdmin plug + AdminAuthHooks handle auth
- Routes go in existing `:superadmin` live_session
- Tests verify 404 for unauthenticated/tenant users
- No new policies needed (read-only, admin-only context)

## Rejected Alternatives
- **Ash custom actions for search/sort** — overkill for small dataset, adds complexity to resource
- **LiveView streams** — unnecessary without pagination/infinite scroll
- **Server-side search with SQL** — premature optimization
- **Impersonation in this ticket** — explicitly deferred to T-023-03
