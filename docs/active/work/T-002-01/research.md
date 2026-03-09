# Research — T-002-01 Landing Page Markup

## Existing route and controller

- `GET /` → `HaulWeb.PageController.home/2` → renders `:home` template
- `HaulWeb.PageHTML` embeds templates from `page_html/*`
- Current `home.html.heex` is Phoenix default boilerplate — will be fully replaced
- Controller uses `HaulWeb, :controller` macro, renders through `:browser` pipeline
- Browser pipeline sets root layout to `{HaulWeb.Layouts, :root}`

## Layout structure

- **Root layout** (`layouts/root.html.heex`): HTML skeleton with `<head>`, CSRF, CSS/JS links, theme toggle script, `{@inner_content}` in `<body>`
- **App layout** (`Layouts.app/1`): Navbar + main + flash. Used by default for pages. For the landing page, we likely bypass `Layouts.app` and render content directly inside root — the landing page has no navbar, it IS the page.
- Root layout links: `/assets/css/app.css`, `/assets/js/app.js`
- Theme toggle script in `<head>` reads `localStorage` and sets `data-theme`

## Tailwind & CSS setup (T-002-03 dependency — already done)

- **Tailwind v4** with `@import "tailwindcss" source(none)` + explicit `@source` directives
- **daisyUI** plugin loaded, themes configured (dark default, light alt)
- **Design tokens** already in place via `@theme` block:
  - `--font-display: Oswald` / `--font-body: Source Sans 3`
  - `--color-background`, `--color-foreground`, `--color-muted-foreground`, `--color-border`, `--color-card`
  - CSS variables `--background: 0 0% 6%` etc. with `[data-theme="light"]` overrides
- **Base styles**: body uses `hsl(var(--background/foreground))`, headings auto-apply Oswald uppercase with tracking
- Google Fonts imported in CSS (Oswald 400-700, Source Sans 3 400/600/700)
- **Heroicons** via Tailwind plugin, available as `hero-{name}` CSS classes, used via `<.icon name="hero-..." />`
- No border radius (`--radius: 0rem`)

## Heroicons availability

- Heroicons v2.2.0 installed via mix deps
- Plugin generates CSS classes from SVGs in `deps/heroicons/optimized/`
- Available: outline (24px), solid, mini (20px), micro (16px)
- Used in templates via `<.icon name="hero-x-mark" class="size-4" />`

### Icon mapping (Lucide → Heroicons)

Prototype uses Lucide icons. Closest Heroicons equivalents:
- Truck → `hero-truck` ✓
- Trash2 → `hero-trash` ✓
- TreePine → no direct match → use `hero-sparkles` or custom SVG
- Wrench → `hero-wrench` ✓ (or `hero-wrench-screwdriver`)
- Hammer → no direct match → use `hero-wrench-screwdriver` or custom SVG
- Package → `hero-cube` or `hero-archive-box` ✓
- Mail → `hero-envelope` ✓
- MapPin → `hero-map-pin` ✓
- Phone → `hero-phone` ✓

## Operator config pattern

- **Content system design** specifies `Haul.Content.SiteConfig` as singleton per tenant
- SiteConfig holds: business_name, phone, email, tagline, service_area, address, coupon_text
- **Not yet implemented** — Content domain resources are designed but code doesn't exist yet
- Ticket says: "Operator config wired from runtime config"
- **Current runtime.exs** has no operator config env vars — only PORT, DATABASE_URL, SECRET_KEY_BASE, PHX_HOST
- For now: use Application config with env var overrides in runtime.exs. When Content domain lands, switch to Ash reads.

## Services data

- Content system defines `Haul.Content.Service` (title, description, icon, sort_order, active)
- Not yet implemented — need hardcoded defaults in config for now
- Six services from spec: Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help

## Print styles

- Mockup reference defines print CSS: white bg, black text, specific font sizes
- Tear-off strip: 8 vertical tabs with writing-mode: vertical-rl
- "Print as Poster" button calls `window.print()` — progressive enhancement
- `@page { margin: 0.3in; size: letter; }`
- `.no-print { display: none; }` for screen-only elements

## Template conventions

- Phoenix 1.8+ uses HEEx templates with function components
- `<.icon>` component available from CoreComponents
- `embed_templates "page_html/*"` auto-loads all `.html.heex` files in directory
- Verified routes use `~p"/"` sigil
- No LiveView needed — pure server-rendered controller action

## What doesn't exist yet

1. No operator config in Application env or runtime.exs
2. No Content domain resources (SiteConfig, Service)
3. No print stylesheet
4. No landing page markup (current template is Phoenix boilerplate)
5. No custom SVG icons for TreePine/Hammer (Heroicons gaps)

## Constraints

- Must work with JS disabled (no LiveView dependency)
- Must be responsive 320px–1440px mobile-first
- Dark theme default, light theme via `data-theme="light"`
- Print-ready with tear-off strip
- Phone must be `tel:` link, email must be `mailto:` link
