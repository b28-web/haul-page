# T-023-02 Research: Accounts List

## Relevant Codebase Areas

### Admin Domain (T-023-01, complete)
- `lib/haul/admin.ex` — Ash domain with AdminUser + AdminToken resources
- `lib/haul/admin/admin_user.ex` — AdminUser resource in public schema (email, name, hashed_password, setup_token_hash, setup_completed)
- `lib/haul/admin/bootstrap.ex` — Bootstrap via ADMIN_EMAIL env var
- `lib/haul_web/plugs/require_admin.ex` — Plug that returns 404 for non-admins; verifies JWT from `_admin_user_token` session key; assigns `:current_admin`
- `lib/haul_web/live/admin_auth_hooks.ex` — `on_mount(:require_admin)` for LiveView; same JWT verification, assigns `:current_admin`
- `lib/haul_web/controllers/admin_session_controller.ex` — Session create/delete

### Router Structure
- Pipeline `:admin_browser` — standard browser pipeline without tenant resolver
- Public admin routes: `/admin/setup/:token`, `/admin/login`, `/admin/session`
- Authenticated admin routes: scope "/admin" with `[:admin_browser, RequireAdmin]` plug pipeline
- LiveView session: `:superadmin` with `on_mount: [{HaulWeb.AdminAuthHooks, :require_admin}]`, layout `{HaulWeb.Layouts, :superadmin}`
- Currently only one authenticated route: `live "/", Admin.DashboardLive`
- New routes `/admin/accounts` and `/admin/accounts/:slug` will go in same live_session

### Superadmin Layout
- `lib/haul_web/components/layouts/superadmin.html.heex`
- Header with "Haul Admin" branding, current_admin.email, theme toggle, sign out
- No sidebar navigation yet — will need nav links when adding accounts page

### Company Resource
- `lib/haul/accounts/company.ex` — public schema, table `companies`
- Fields: id, slug (unique), name, timezone, subscription_plan (starter|pro|business|dedicated), stripe_customer_id, stripe_subscription_id, domain, domain_status (pending|verified|provisioning|active), onboarding_complete, dunning_started_at, domain_verified_at, inserted_at, updated_at
- Actions: `:read` (default), `:create_company`, `:update_company`, `:by_stripe_customer_id`
- No `:list` or `:search` custom read action — default `:read` returns all

### User Resource (Tenant-Scoped)
- `lib/haul/accounts/user.ex` — table `users` in tenant schema via `:context` multitenancy
- Fields: id, email, name, role (owner|dispatcher|crew), phone, active, hashed_password, inserted_at, updated_at
- Querying users requires tenant context: `Ash.read(User, tenant: "tenant_#{slug}")`

### Content — SiteConfig (Tenant-Scoped)
- `lib/haul/content/site_config.ex` — tenant-scoped, determines if site has content
- Checking "has content" means querying SiteConfig with tenant context

### Existing LiveView Patterns
- `Admin.DashboardLive` — minimal placeholder, assigns page_title in mount
- App LiveViews (e.g., OnboardingLive, BillingLive) use AshPhoenix.Form, event handlers, component composition
- No existing table/list components in admin views yet

### Test Patterns
- `test/haul_web/live/admin/security_test.exs` — patterns for admin auth testing
  - `create_bootstrap_admin/1` — creates AdminUser with raw setup token
  - `setup_completed_admin/1` — completes setup, signs in, returns JWT token
  - `init_test_session(%{_admin_user_token: token})` — sets admin session
  - Tests verify 404 for unauthenticated access
- `test/support/conn_case.ex` — `create_authenticated_context/1` creates company + tenant + user + token

### Status Indicators Needed
1. **Tenant provisioned** — check if `tenant_{slug}` schema exists in PostgreSQL
2. **Has content** — check if SiteConfig exists in tenant schema
3. **Domain verified** — `company.domain_status` in [:verified, :active] or `domain_verified_at` is set

### Constraints
- Read-only — no mutation actions
- All queries from public schema (no tenant scoping for company list)
- User count per company requires per-tenant query (could be expensive for many tenants)
- Non-superadmin must get 404 (existing pattern from RequireAdmin)
- Sorting/filtering on company list

### Dependencies
- T-023-01 (superadmin auth) — DONE, provides auth infrastructure
- T-023-03 (impersonation) — future ticket, detail view just needs placeholder "Impersonate" button
