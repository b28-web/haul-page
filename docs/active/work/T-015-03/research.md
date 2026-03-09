# T-015-03 Research: Marketing Landing Page

## What exists

### TenantResolver plug (`lib/haul_web/plugs/tenant_resolver.ex`)
- Resolution order: custom domain → subdomain → fallback
- `extract_subdomain("haulpage.com", "haulpage.com")` returns `nil`
- When no company found: returns `:fallback`, sets `current_tenant = nil`
- Fallback uses operator config slug, sets tenant schema but `current_tenant` stays nil
- **Key insight:** On bare domain, `current_tenant` is nil AND subdomain is nil. On a valid subdomain, `current_tenant` is a Company struct. On an invalid subdomain, `current_tenant` is nil but subdomain was extracted.

### Router (`lib/haul_web/router.ex`)
- All browser routes go through `:browser` pipeline which includes TenantResolver
- `get "/", PageController, :home` — single route for `/`
- No conditional routing based on tenant presence
- `/app/signup` already exists (SignupLive)

### PageController (`lib/haul_web/controllers/page_controller.ex`)
- `home/2` loads tenant content via ContentHelpers, renders `:home` template
- Uses `put_layout(false)` — no layout wrapper
- Falls back to operator config when no real tenant exists

### Operator landing page (`lib/haul_web/controllers/page_html/home.html.heex`)
- 152 lines. Hero, services grid, why-hire-us, footer CTA with print coupon strip
- Uses design tokens: `bg-background`, `text-foreground`, `text-muted-foreground`
- `font-display` (Oswald) for headings, responsive grid layouts
- Print-specific tear-off coupon strip

### Design system (`assets/css/app.css`)
- Dark theme default (pure grayscale oklch)
- Oswald (display) + Source Sans 3 (body) via Google Fonts
- Custom CSS properties: `--background`, `--foreground`, `--muted-foreground`, `--border`, `--card`
- daisyUI disabled themes, custom grayscale
- No border-radius (flat design)

### Layouts (`lib/haul_web/components/layouts/`)
- `root.html.heex` — HTML skeleton, theme script, Stripe JS, CSS
- `admin.html.heex` — Sidebar + authenticated header for `/app/*`
- No marketing-specific layout exists

### Tests (`test/haul_web/controllers/page_controller_test.exs`)
- 7 tests, all use ConnCase with `async: false`
- Setup provisions a company + seeds content, tears down tenant schemas on exit
- Tests assert on operator-specific content (business name, phone, services)

## Constraints

1. In dev/test, `base_domain` = "localhost". Subdomain extraction always returns nil. Need a way to detect "bare domain" that works in dev.
2. `current_tenant` is nil in both bare-domain and fallback cases — can't distinguish by `current_tenant` alone.
3. The fallback behavior (operator config slug) means the operator landing page loads even without a real subdomain. The marketing page must take precedence on the bare domain.
4. `/signup` route exists but the LiveView may not be fully implemented (T-015-01 is still in progress).

## Key decision point

How to distinguish "bare domain" (show marketing page) from "subdomain with no matching company" (show operator fallback or 404)? Options:
- Check if `host == base_domain` in the controller
- Add an assign in TenantResolver (e.g., `:is_bare_domain`)
- Use a separate plug/pipeline for marketing routes

The cleanest approach is to add an `:is_platform_host` assign in TenantResolver when the host matches the bare domain exactly, then branch in the controller.
