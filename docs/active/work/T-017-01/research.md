# T-017-01 Research: Domain Settings UI

## Relevant Files & Modules

### Company Resource (`lib/haul/accounts/company.ex`)
- `domain` attribute: nullable string, unique identity constraint (`:unique_domain`)
- `update_company` action accepts `:domain` in its accept list
- No domain status tracking — only the raw domain string exists
- Slug always present (not-null), used for subdomain routing

### TenantResolver Plug (`lib/haul_web/plugs/tenant_resolver.ex`)
- Resolution order: custom domain → subdomain → fallback
- `resolve_by_domain/1`: `Ash.Query.filter(domain == ^host)` — exact match on host
- Custom domains work immediately once `company.domain` is set
- No verification or TLS state — the plug just does a DB lookup

### Billing Feature Gates (`lib/haul/billing.ex`)
- `@feature_matrix` maps `:custom_domain` to `[:pro, :business, :dedicated]`
- `Billing.can?(company, :custom_domain)` — returns false for `:starter`
- Feature labels: `custom_domain: "Custom Domain"`
- Clean API: check plan, get features, get labels

### Admin Layout (`lib/haul_web/components/layouts/admin.html.heex`)
- Sidebar nav: Dashboard, Content (expandable), Bookings, Settings, Billing
- Settings and Billing are flat links at top level (not nested)
- Active state: `@current_path` with `String.starts_with?` checks
- No expandable subsection for Settings currently

### Router (`lib/haul_web/router.ex`)
- Authenticated routes in `live_session :authenticated` with `AuthHooks.require_auth`
- Layout: `{HaulWeb.Layouts, :admin}`
- `/settings` → `App.DashboardLive` (stub), `/settings/billing` → `App.BillingLive`
- New route: `/settings/domain` → `App.DomainSettingsLive`

### Existing LiveView Patterns (BillingLive)
- Mount: read `socket.assigns.current_company`, set page_title and local assigns
- Render: inline `~H` template with Tailwind classes matching dark theme
- Events: `handle_event` pattern with Ash changesets for updates
- Feature gating: conditional rendering in template
- External redirects via `phx-hook="ExternalRedirect"` + `push_event("redirect", ...)`

### Test Patterns (BillingLiveTest)
- `use HaulWeb.ConnCase, async: false`
- `create_authenticated_context()` → `%{company, tenant, user, token}`
- `log_in_user(conn, ctx)` for auth
- `cleanup_tenants()` on_exit
- LiveView testing: `live(conn, path)` → `{:ok, view, html}`, `render_click`, assert on HTML

## Key Constraints

1. **No domain_status field exists** — Company only has `domain` (string). Need to add `domain_status` for tracking verification state (pending → verified → active).
2. **DNS verification is a backend concern** — this ticket is UI-focused. T-017-02 handles cert provisioning. But the UI needs to show verification states and a "Verify DNS" button.
3. **Feature gating is straightforward** — `Billing.can?/2` already works. Starter users see upgrade prompt.
4. **base_domain config** — `Application.get_env(:haul, :base_domain, "localhost")` used for CNAME instructions.
5. **No Oban workers for DNS verification yet** — this ticket should create the UI and a simple DNS check module. Background verification can be inline (`:inet_res.lookup`) for now.

## DNS Verification Approach
- Elixir's `:inet_res.lookup/3` can resolve CNAME records
- Check if domain's CNAME points to base_domain (e.g., "haulpage.com")
- Synchronous check is fine for a "Verify DNS" button click
- Could also accept A record pointing to the app's IP

## Assumptions
- T-017-02 handles actual TLS provisioning (Fly.io cert API)
- This ticket builds the UI + basic DNS check + domain status tracking
- Domain validation: must be a valid hostname, no protocol prefix, no path
