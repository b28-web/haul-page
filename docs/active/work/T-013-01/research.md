# T-013-01 Research: App Layout

## Relevant Files & Modules

### Router (`lib/haul_web/router.ex`)
- Pipelines: `:browser` (session, CSRF, tenant resolver), `:api`, `:api_with_tenant`
- Public routes: `/`, `/scan`, `/book`, `/pay/:job_id`, health, QR, places, stripe webhook
- No `/app` scope or auth pipeline exists yet
- TenantResolver plug already runs in `:browser` pipeline — sets `conn.assigns.tenant` and `conn.assigns.current_tenant`

### Authentication (`lib/haul/accounts/user.ex`)
- AshAuthentication extension with password + magic_link strategies
- Token-based auth (AshAuthentication.Token resource)
- User has `:role` enum — `:owner`, `:dispatcher`, `:crew` (default crew)
- User is multi-tenant (`:context` strategy)
- **No `ash_authentication_phoenix` dep** — no built-in auth plugs, no sign-in LiveView generators
- Token signing secret from `Application.fetch_env(:haul, :token_signing_secret)`
- Password and magic link senders are stubbed (TODO)

### Layouts (`lib/haul_web/components/layouts.ex` + `layouts/root.html.heex`)
- `embed_templates "layouts/*"` — any `.heex` file in layouts/ becomes a component
- `app/1` defined inline in layouts.ex — generic Phoenix scaffold navbar (links to phoenixframework.org)
- `root.html.heex` — minimal HTML skeleton, theme toggle JS, Stripe JS, dark theme default
- `flash_group/1` and `theme_toggle/1` components available
- No `app.html.heex` template file exists

### HaulWeb (`lib/haul_web.ex`)
- `:live_view` macro imports `html_helpers()` (CoreComponents, Layouts, JS, verified_routes)
- No auth-specific assigns or hooks injected into LiveView lifecycle
- `static_paths` includes images, uploads, fonts

### Tenant Resolution (`lib/haul_web/plugs/tenant_resolver.ex`)
- Resolves Company from Host header (custom domain → subdomain → fallback)
- Sets `conn.assigns.current_tenant` (Company struct or nil) and `conn.assigns.tenant` (schema string)
- Already in `:browser` pipeline — available to `/app` routes

### Company (`lib/haul/accounts/company.ex`)
- Attributes: id, slug, name, timezone, subscription_plan, stripe_customer_id, domain
- ProvisionTenant change creates Postgres schema on company creation
- Not multi-tenant itself (companies are in public schema)

### CSS/Theme (`assets/css/app.css`)
- Tailwind 4.1.12 + daisyUI (themes disabled, custom dark/light)
- CSS custom properties: `--background`, `--foreground`, `--border`, `--card`, `--muted-foreground`
- Fonts: Oswald (display/headings), Source Sans 3 (body)
- Dark theme is default (near-black bg, near-white text)
- Sharp corners (`--radius: 0rem`)

### Existing LiveViews
- BookingLive, PaymentLive, ScanLive — all public, no auth
- Pattern: `mount/3` resolves tenant via `ContentHelpers.resolve_tenant()`
- No `on_mount` hooks used

### Core Components (`lib/haul_web/components/core_components.ex`)
- `.flash`, `.button` (primary/soft), `.input` (all types), `.icon` (heroicons)
- No sidebar, nav, or layout-specific components

### Test Infrastructure (`test/support/conn_case.ex`)
- Standard ConnCase with SQL sandbox
- No auth helpers (no `log_in_user`, no session injection)

## Constraints & Assumptions

1. **No ash_authentication_phoenix**: Must build auth plugs manually. AshAuthentication provides `AshAuthentication.subject_to_user/2` and session token APIs but no Phoenix-specific plugs/hooks.
2. **Multi-tenancy**: User is tenant-scoped. To load a user from session, we need both the token AND the tenant context. TenantResolver already resolves tenant from Host.
3. **Role gating**: Ticket says "requires authenticated owner/dispatcher" — crew role should not access `/app`.
4. **Login page**: `/app/login` needs password form. Magic link sender is stubbed, so password auth is the practical path for now.
5. **Session token flow**: AshAuthentication stores a bearer token in session after sign_in action. To restore user: extract token from session → verify with AshAuthentication → get user.
6. **No existing logout route**: Need to clear session and redirect.
7. **Sidebar nav items**: Dashboard, Content, Bookings, Settings — only Dashboard is implemented in this ticket; others are placeholders.
8. **Mobile responsive**: Hamburger menu + slide-out sidebar on small screens.
9. **T-012-01 (tenant-plug)** is a sibling ticket — TenantResolver already exists and works. This ticket doesn't need to modify it.
