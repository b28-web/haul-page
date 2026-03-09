# T-015-03 Structure: Marketing Landing Page

## Files modified

### `lib/haul_web/plugs/tenant_resolver.ex`
- In `call/2`: after resolution, add `assign(:is_platform_host, bool)`
- Platform host = true when: host matches base_domain exactly (no subdomain)
- In dev: localhost == localhost → true. `joes.localhost` extracts subdomain → false.

### `lib/haul_web/controllers/page_controller.ex`
- `home/2`: check `conn.assigns[:is_platform_host]`
  - If true: delegate to `marketing/2`
  - If false: existing operator landing logic
- New `marketing/2` private function: assigns page_title, renders `:marketing` template with `put_layout(false)`

### `lib/haul_web/controllers/page_html.ex` (if exists) or auto-discovered
- No changes needed — Phoenix auto-discovers templates in `page_html/` directory

## Files created

### `lib/haul_web/controllers/page_html/marketing.html.heex`
~200 lines. Sections:
- Sticky nav: "HAUL" logo left, "Get Started" button right
- Hero: large heading, subtitle, CTA button
- Features grid: 6 feature cards with icons
- How it works: 3 numbered steps
- Pricing table: 4 tiers in responsive grid
- Demo link section
- Footer with copyright

### `test/haul_web/controllers/marketing_page_test.exs`
Tests for the marketing landing page:
- GET / on bare domain returns marketing content
- Contains hero heading, pricing tiers, feature descriptions
- CTA links to /app/signup
- Does not contain operator-specific content (phone, services grid)

## Files unchanged
- `lib/haul_web/router.ex` — no route changes, same `get "/", PageController, :home`
- `assets/css/app.css` — existing design system sufficient
- `lib/haul_web/components/layouts/root.html.heex` — no changes

## Module boundaries
- TenantResolver: adds one assign, no new public API
- PageController: one new private function + template
- No new modules or contexts needed
