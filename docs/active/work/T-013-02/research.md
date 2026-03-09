# T-013-02 Research: Site Config Editor

## Objective

Build a LiveView form at `/app/content/site` that lets operators edit their SiteConfig (business name, phone, email, tagline, service area, primary color) within the authenticated admin UI.

## Existing Infrastructure

### Content.SiteConfig Resource (`lib/haul/content/site_config.ex`)

Ash resource with AshPostgres data layer, multi-tenant via `:context` strategy.

**Attributes (all public):**
- `business_name` (string, required)
- `phone` (string, required)
- `email` (string, optional)
- `tagline` (string, optional)
- `service_area` (string, optional)
- `address` (string, optional)
- `coupon_text` (string, default "10% OFF")
- `meta_description` (string, optional)
- `primary_color` (string, default "#0f0f0f")
- `logo_url` (string, optional)

**Actions:**
- `:read` — default read
- `:create_default` — accepts all fields
- `:edit` — update action, accepts all fields

**Code interface:**
- `SiteConfig.current(tenant: tenant)` — reads
- `SiteConfig.edit(config, changes, tenant: tenant)` — updates

### Router (`lib/haul_web/router.ex`)

Authenticated admin routes are in a `scope "/app"` with:
- `pipe_through :browser` (includes TenantResolver plug)
- `live_session :authenticated` with `on_mount: [{HaulWeb.AuthHooks, :require_auth}]`
- Layout: `{HaulWeb.Layouts, :admin}`
- Currently maps `/content`, `/bookings`, `/settings` all to `App.DashboardLive` (placeholder)

### AuthHooks (`lib/haul_web/live/auth_hooks.ex`)

On mount, sets:
- `socket.assigns.current_user` — User struct
- `socket.assigns.current_company` — Company struct
- `socket.assigns.current_path` — updated via handle_params hook

Requires owner or dispatcher role. Tenant is derived from the company slug.

### Admin Layout (`lib/haul_web/components/layouts/admin.html.heex`)

Sidebar with nav links: Dashboard, Content, Bookings, Settings. Content link highlights when `@current_path` starts with `/app/content`. Flash group rendered in main content area.

### Form Pattern (from BookingLive)

Uses AshPhoenix.Form:
1. `AshPhoenix.Form.for_create` or `for_update` to build form
2. `validate` event calls `AshPhoenix.Form.validate`
3. `submit` event calls `AshPhoenix.Form.submit`
4. Stores both `ash_form` (for validation state) and `form` (Phoenix form via `to_form`)
5. Uses `<.input>` core component for rendering fields

### ContentHelpers (`lib/haul_web/content_helpers.ex`)

`load_site_config(tenant)` reads SiteConfig from Ash, falls back to operator config map. Returns either a SiteConfig struct or a plain map.

### Test Patterns

- `DashboardLiveTest` uses `create_authenticated_context(role: :owner)` + `log_in_user(conn, ctx)` for auth setup
- `SiteConfigTest` creates Company, derives tenant schema, creates/updates SiteConfig via Ash changesets
- Cleanup via `on_exit` dropping tenant schemas

## Key Constraints

1. **SiteConfig may not exist yet** — for a new tenant, no SiteConfig record exists. The form must handle both create (first save) and update (subsequent saves).
2. **Tenant context** — AuthHooks provides `current_company` but not `tenant` directly. Need to derive tenant schema from company slug.
3. **Route within live_session** — must be added to the existing `:authenticated` live_session block.
4. **AshPhoenix.Form** — supports `for_create` and `for_update`. Need to detect which to use based on existing record.
5. **Six AC fields** — business_name, phone, email, tagline, service_area, primary_color. SiteConfig has more fields but AC specifies these six.

## File Inventory

| File | Relevance |
|------|-----------|
| `lib/haul/content/site_config.ex` | Resource definition — actions, attributes |
| `lib/haul_web/router.ex` | Add route to authenticated scope |
| `lib/haul_web/live/app/dashboard_live.ex` | Pattern for authenticated LiveView |
| `lib/haul_web/live/booking_live.ex` | AshPhoenix.Form pattern reference |
| `lib/haul_web/live/auth_hooks.ex` | Sets current_user, current_company |
| `lib/haul_web/components/core_components.ex` | `<.input>` component |
| `lib/haul_web/components/layouts/admin.html.heex` | Admin layout with sidebar |
| `lib/haul_web/content_helpers.ex` | `load_site_config/1` |
| `test/haul_web/live/app/dashboard_live_test.exs` | Test pattern for authenticated LiveView |
| `test/haul/content/site_config_test.exs` | SiteConfig test patterns |
