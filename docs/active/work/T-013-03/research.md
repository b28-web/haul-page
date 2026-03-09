# T-013-03 Research: Services CRUD

## Service Ash Resource (`lib/haul/content/service.ex`)

- **Attributes:** title (string, required), description (string, required), icon (string, required — Heroicon names like "hero-truck"), sort_order (integer, default 0), active (boolean, default true), timestamps
- **Actions:** `:read` (auto-sorts by sort_order ASC via preparation), `:add` (create — accepts title, description, icon, sort_order), `:edit` (update — accepts title, description, icon, sort_order, active), `:destroy` (default)
- **Postgres:** schema-per-tenant via `:context` strategy. Table: `services`. AshPaperTrail for change tracking (versions table: `services_versions`)
- **Key behavior:** All reads auto-sorted by `sort_order ASC` via preparation — drag-to-reorder just needs to update sort_order values

## Content Domain (`lib/haul/content.ex`)

Single-file Ash Domain registering: SiteConfig, Service, GalleryItem, Endorsement, Page (each with .Version counterparts). All queries use `Ash.read(Service, tenant: tenant)`.

## App Layout (T-013-01 — completed)

- **Layout:** `lib/haul_web/components/layouts/admin.html.heex` — sidebar + header + content area
- **Sidebar nav items:** Dashboard (`/app`), Content (`/app/content`), Bookings (`/app/bookings`), Settings (`/app/settings`)
- **Component:** `sidebar_link/1` with icon + label, active state styling
- **Mobile:** hamburger menu, slide-out sidebar with overlay

## Existing CRUD Pattern: SiteConfigLive (`lib/haul_web/live/app/site_config_live.ex`)

- Uses `AshPhoenix.Form` for form state (validation + submission)
- Mount: loads existing data, derives tenant from `current_company.slug`
- Events: `validate` (real-time via `AshPhoenix.Form.validate`), `save` (submit via `AshPhoenix.Form.submit`)
- Flash messages on success/error
- Template uses `<.input field={@form[:field_name]}` from CoreComponents

## Landing Page Services Grid (`lib/haul_web/controllers/page_html/home.html.heex`)

```heex
<div class="grid grid-cols-2 md:grid-cols-3 gap-6">
  <div :for={service <- @services} class="text-center">
    <.icon name={service.icon} class="size-7 mx-auto mb-3 stroke-1" />
    <h3 class="...">{service.title}</h3>
    <p class="...">{service.description}</p>
  </div>
</div>
```

- Data loaded via `ContentHelpers.load_services(tenant)` — filters active only, returns sorted by sort_order
- No cache — changes reflect immediately on page reload

## Router (`lib/haul_web/router.ex`)

Authenticated admin scope:
```elixir
scope "/app", HaulWeb do
  pipe_through :browser
  live_session :authenticated,
    on_mount: [{HaulWeb.AuthHooks, :require_auth}],
    layout: {HaulWeb.Layouts, :admin} do
    live "/", App.DashboardLive
    live "/content", App.DashboardLive
    live "/content/site", App.SiteConfigLive
    live "/bookings", App.DashboardLive
    live "/settings", App.DashboardLive
  end
end
```

New route needed: `live "/content/services", App.ServicesLive`

## Reorder Patterns

- `sort_order` field exists on Service (integer, default 0), also on GalleryItem
- No existing drag-to-reorder UI in codebase — must implement
- Options: arrow buttons (no JS deps), SortableJS (external lib), custom LiveView drag handlers

## Seed Data (`lib/haul/content/seeder.ex`)

- Seeds from `priv/content/services/*.yml` — YAML with title, description, icon, sort_order
- Idempotent: matches by title, creates or updates
- Per-tenant overrides supported in `priv/content/operators/{slug}/services/`

## CoreComponents Available

- `<.input>` — text, select, textarea, checkbox types
- `<.button>`, `<.table>`, `<.header>`, `<.flash>`
- `<.modal>` — for add/edit forms
- `<.icon>` — renders Heroicons by name

## What Exists vs. What's Needed

**Ready:** Service resource with sort_order + auto-sort, Content domain, auth + admin layout, SiteConfigLive pattern, router scope, core components, seed task, landing page rendering

**Must build:** ServicesLive LiveView (list + add/edit/delete + reorder), router entry, sidebar nav update (Content submenu with Services link), icon selector dropdown, minimum-1-service validation on delete

## Constraints

- No external JS dependencies (no SortableJS) — use arrow buttons or LiveView-native drag
- Must work with schema-per-tenant (derive tenant from current_company.slug)
- Changes must reflect on landing page immediately (no cache)
- Minimum 1 service required — cannot delete last one
