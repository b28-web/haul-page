# T-013-06 Research: Browser QA for Content Admin UI

## Scope

Playwright MCP verification of the content admin UI at `/app`. Confirm an authenticated operator can view and edit site content through the admin interface, and changes reflect on public pages.

## Admin Architecture

### Layout (`lib/haul_web/components/layouts/admin.html.heex`)

- Fixed left sidebar on desktop (md: breakpoint), hamburger overlay on mobile
- Sidebar nav: Dashboard, Content (submenu: Site Settings, Services, Gallery, Endorsements), Bookings, Settings
- Header: company name, user email, theme toggle, sign-out button
- Flash messages via `flash_group` component
- `@current_path` tracks active route for nav highlighting

### Authentication (`lib/haul_web/live/auth_hooks.ex`)

- `AuthHooks.require_auth` — on_mount hook for all `/app/*` routes
- Loads user from JWT in session, requires `:owner` or `:dispatcher` role
- Redirects unauthenticated users to `/app/login`
- Sets assigns: `current_user`, `current_company`, `current_path`, `tenant`

### Login Flow

- `/app/login` — LoginLive renders email/password form
- POST to `/app/session` → AppSessionController.create
- Sets session cookies (user_token, tenant) → redirect to `/app`

## Content Admin LiveViews

### SiteConfigLive (`lib/haul_web/live/app/site_config_live.ex`)
- Route: `/app/content/site`
- Loads existing SiteConfig or prepares create form
- Fields: business_name, phone, email, tagline, service_area, address, coupon_text, primary_color, logo_url, meta_description
- AshPhoenix.Form with phx-change validate, phx-submit save
- Success flash: "Site settings updated"

### ServicesLive (`lib/haul_web/live/app/services_live.ex`)
- Route: `/app/content/services`
- Lists services with sort order, edit/delete/reorder
- Icon selector with 15 Heroicon options
- Delete protection: cannot delete last service
- Events: add, edit, validate, save, cancel, delete, move_up, move_down

### GalleryLive (`lib/haul_web/live/app/gallery_live.ex`)
- Route: `/app/content/gallery`
- Grid of before/after photo pairs
- LiveView file upload (max 5MB)
- Modal add/edit form with alt_text, caption, featured, active flags
- Events: add, edit, validate, save, delete, move-up, move-down, toggle-active

### EndorsementsLive (`lib/haul_web/live/app/endorsements_live.ex`)
- Route: `/app/content/endorsements`
- List testimonials with star ratings (★/☆)
- Fields: customer_name, quote_text, star_rating (1-5), source enum, date, featured, active
- Sort order management, delete protection via PaperTrail cleanup

### DashboardLive (`lib/haul_web/live/app/dashboard_live.ex`)
- Routes: `/app`, `/app/content`
- Welcome message with user name, site URL link

## Router Setup (`lib/haul_web/router.ex`)

```
# Public
live "/login", App.LoginLive
post "/session", AppSessionController, :create

# Authenticated (admin layout, AuthHooks.require_auth on_mount)
live "/", App.DashboardLive
live "/content", App.DashboardLive
live "/content/site", App.SiteConfigLive
live "/content/services", App.ServicesLive
live "/content/gallery", App.GalleryLive
live "/content/endorsements", App.EndorsementsLive
```

## Tenant Context

- Admin pages use session-based tenant from login
- Each LiveView passes `tenant: socket.assigns.tenant` to Ash queries
- Content resources use `:context` multitenancy (schema-per-tenant)

## Existing Test Coverage

- 6 LiveView test files under `test/haul_web/live/app/` with unit tests
- `ConnCase` helpers: `create_authenticated_context/1`, `log_in_user/2`, `cleanup_tenants/0`
- Previous browser QA tickets (T-002-04, T-003-04, T-005-04, T-006-05, T-009-03, T-012-05) all used Playwright MCP against localhost:4000

## Playwright MCP

- Configured in `.mcp.json` with headless Chrome
- Tools: browser_navigate, browser_snapshot, browser_click, browser_type, browser_fill_form, browser_resize
- Snapshots return accessibility tree (not visual screenshots)

## Content on Public Pages

- Landing page (`/`) rendered by PageController — uses SiteConfig fields (business_name, tagline, phone, etc.)
- ContentHelpers module provides `site_config/1`, `services/1`, `gallery_items/1`, `endorsements/1`
- Changes saved in admin should reflect immediately on public pages (same DB, no caching layer)

## Key Constraints

1. Dev server must be running on port 4000
2. Need an authenticated session to access `/app/*` routes
3. Playwright can navigate and fill forms but login requires form submission + cookie management
4. Content seeded for default operator (junk-and-handy)
