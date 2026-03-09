# T-023-02 Structure: Accounts List

## Files Created

### `lib/haul_web/live/admin/accounts_live.ex`
- `HaulWeb.Admin.AccountsLive` — list view at `/admin/accounts`
- Mount: load all companies, batch-check tenant schemas, check SiteConfig per provisioned tenant
- Assigns: `companies`, `filtered_companies`, `search`, `sort_by`, `sort_dir`, `tenant_statuses`
- Events: `search` (filter), `sort` (toggle column sort)
- Render: search input, sortable table headers, status indicator badges, rows link to detail

### `lib/haul_web/live/admin/account_detail_live.ex`
- `HaulWeb.Admin.AccountDetailLive` — detail view at `/admin/accounts/:slug`
- Mount: load company by slug, load tenant status, load users, load SiteConfig
- Assigns: `company`, `users`, `site_config`, `tenant_provisioned`, `has_content`, `domain_verified`
- Render: company attributes DL, users table, status badges, impersonate button (disabled)
- Handle not found: redirect to `/admin/accounts` with flash

### `test/haul_web/live/admin/accounts_live_test.exs`
- Tests for list view: renders table, search filters, sort toggles, status indicators
- Security: unauthenticated returns 404, tenant user returns 404
- Setup: create companies, provision tenants, create users

### `test/haul_web/live/admin/account_detail_live_test.exs`
- Tests for detail view: renders company info, user list, status indicators
- Not found: redirect with flash for invalid slug
- Security: same 404 pattern

## Files Modified

### `lib/haul_web/router.ex`
- Add two routes in `:superadmin` live_session:
  ```elixir
  live "/accounts", Admin.AccountsLive
  live "/accounts/:slug", Admin.AccountDetailLive
  ```

### `lib/haul_web/components/layouts/superadmin.html.heex`
- Add nav links: Dashboard (`/admin`), Accounts (`/admin/accounts`)
- Highlight active link based on current path

## Module Boundaries

```
Router
  └─ /admin/accounts       → Admin.AccountsLive
  └─ /admin/accounts/:slug → Admin.AccountDetailLive

AccountsLive
  ├─ Ash.read!(Company)                    # public schema, no tenant
  ├─ SQL query for tenant schema existence  # batch, one query
  └─ Ash.read(SiteConfig, tenant: ...)     # per provisioned tenant

AccountDetailLive
  ├─ Ash.read!(Company) + find by slug     # public schema
  ├─ Ash.read!(User, tenant: ...)          # tenant-scoped
  ├─ Ash.read(SiteConfig, tenant: ...)     # tenant-scoped
  └─ SQL schema existence check            # single tenant
```

## No Changes To
- Company resource (no new actions needed — default `:read` suffices)
- User resource (default `:read` with `authorize?: false` for superadmin queries)
- Admin domain or AdminUser resource
- RequireAdmin plug or AdminAuthHooks (existing auth covers new routes)
