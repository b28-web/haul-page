# T-005-01 Research: Scan Page Layout

## Ticket Summary

Build `/scan` — QR code landing page. LiveView. Three sections: hero CTA (call/book), before/after gallery, customer endorsements. Mobile-first, dark theme, same typography as landing page.

## Existing Patterns

### Routing & Page Serving

- Router at `lib/haul_web/router.ex` — single browser scope with `pipe_through :browser`
- Landing page uses `PageController` (server-rendered, `put_layout(false)`)
- LiveView socket already configured in endpoint (`/live` path, websocket + longpoll)
- `Phoenix.LiveView.Router` already imported in router macro
- No LiveView pages exist yet — this will be the first

### Operator Config

- `config :haul, :operator` in `config/config.exs` — business_name, phone, email, tagline, service_area, coupon_text, services list
- Accessed via `Application.get_env(:haul, :operator, [])` in PageController
- Same pattern applies in LiveView `mount/3`

### Layout System

- Root layout: `lib/haul_web/components/layouts/root.html.heex` — minimal HTML shell with theme script, CSS, JS
- App layout: `lib/haul_web/components/layouts/app.html.heex` — has navbar (not wanted for scan page)
- Landing page bypasses both with `put_layout(false)` — renders standalone `<main>` tag
- For scan page LiveView: root layout is fine (provides CSS/JS), but app layout must be skipped

### CSS & Theme

- Tailwind 4 with custom `@theme` block in `assets/css/app.css`
- Font families: `--font-display: 'Oswald'`, `--font-body: 'Source Sans 3'`
- Dark theme default: `--background: oklch(...)`, `--foreground: oklch(...)` (pure grayscale)
- CSS custom properties: `--background`, `--foreground`, `--muted-foreground`, `--border`, `--card`
- Headings auto-uppercase via base styles (`h1-h6 { text-transform: uppercase }`)
- No border radius (`--radius: 0rem`)
- daisyUI disabled, custom theme tokens defined

### Components Available

- `<.icon name="hero-..." />` — Heroicon rendering
- `<.button>` — polymorphic button/link with variants
- `<.header>` — page header with title/subtitle
- CoreComponents auto-imported via `html_helpers/0` in HaulWeb

### LiveView Macros

- `HaulWeb.live_view` macro provides: `use Phoenix.LiveView` + html_helpers (Gettext, CoreComponents, verified routes, Layouts alias)
- Template embedding via `embed_templates` in a companion HTML module, or inline `render/1`

### Content System (Future)

- `docs/knowledge/content-system.md` defines `Haul.Content.GalleryItem` and `Haul.Content.Endorsement` Ash resources
- Not yet implemented — no Ash resources or migrations exist
- Ticket says "hardcoded list initially, database-backed later"
- Gallery: before_image_url, after_image_url, caption, alt_text, sort_order, featured
- Endorsement: customer_name, quote_text, star_rating, source, date, featured

### Test Patterns

- `HaulWeb.ConnCase` for controller tests
- Pattern: `setup` reads operator config, tests assert content presence
- For LiveView: use `live(conn, "/scan")` to mount, assert HTML content
- 12 tests currently passing (7 page controller + others)

### Assets & Images

- `priv/static/` is the static file directory (digested by phx.digest)
- `HaulWeb.static_paths/0` includes `~w(assets fonts images favicon.ico robots.txt)`
- No images exist yet in `priv/static/images/`
- For initial hardcoded gallery: use placeholder images or stock photos in `priv/static/images/gallery/`

## Constraints

1. **First LiveView page** — establishes the pattern for all future LiveView pages (booking, admin)
2. **No Ash resources yet** — gallery and endorsements must be hardcoded in config or module attributes
3. **Mobile-first** — QR codes are scanned by phones; desktop is secondary
4. **No `/book` route exists** — CTA button should link to `/book` but it won't resolve yet (that's T-003-01)
5. **Same theme** — must match landing page's dark grayscale aesthetic exactly

## Key Files

| File | Relevance |
|------|-----------|
| `lib/haul_web/router.ex` | Add `live "/scan"` route |
| `lib/haul_web.ex` | `live_view` macro definition |
| `lib/haul_web/components/core_components.ex` | Reusable components |
| `lib/haul_web/components/layouts/root.html.heex` | Root HTML layout |
| `lib/haul_web/controllers/page_html/home.html.heex` | Landing page template (style reference) |
| `config/config.exs` | Operator config + potential gallery/endorsement config |
| `assets/css/app.css` | Theme tokens, typography, base styles |
| `test/haul_web/controllers/page_controller_test.exs` | Test pattern reference |
