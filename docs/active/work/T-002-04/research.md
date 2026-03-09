# T-002-04 Research — Browser QA

## Ticket Summary

Automated browser QA for the landing page using Playwright MCP. Verify rendering, navigation, mobile responsiveness, and print readiness — no manual QA.

## Dependencies

- **T-002-01** (landing-page-markup): phase=done. Server-rendered HEEx at `GET /` via `PageController.home`.
- **T-002-02** (print-stylesheet): phase=done. Print styles in `assets/css/app.css` with `@media print` rules.
- **T-002-03** (tailwind-setup): phase=done. Tailwind 4.1.12 with custom theme, dark default.

## What Exists

### Landing Page Structure (`lib/haul_web/controllers/page_html/home.html.heex`)

Four sections within `<main>`:

1. **Hero** (`<section>` #1, lines 3–42):
   - Eyebrow: "Licensed & Insured · Serving {service_area}"
   - H1: "Junk Hauling" (text-6xl/8xl/9xl responsive)
   - Subtitle: "& Handyman Services"
   - Tagline paragraph
   - Phone `tel:` link (text-5xl/7xl)
   - Email `mailto:` + location with hero-envelope/hero-map-pin icons

2. **Services Grid** (`<section>` #2, lines 45–57):
   - H2: "What We Do"
   - 6 services in 2-col mobile / 3-col desktop grid
   - Each: icon + title + description

3. **Why Hire Us** (`<section>` #3, lines 60–73):
   - H2: "Why Hire Us"
   - 6 dash-prefixed items in 2-col layout

4. **Footer CTA** (`<footer>`, lines 76–133):
   - H2: "Ready to Get Started?"
   - Phone CTA button (screen only via `print:hidden`)
   - Print button (hidden by default, shown via JS)
   - Print-only URL + phone block
   - Tear-off strip: 8 vertical tabs (hidden on screen, `print:block`)

### Routing

- `GET /` → `PageController.home` (not LiveView)
- Layout disabled (`put_layout(false)`) — template is self-contained
- Root layout at `lib/haul_web/components/layouts/root.html.heex` provides HTML shell

### Operator Config (default values from `config/config.exs`)

- business_name: "Junk & Handy"
- phone: "(555) 123-4567"
- email: "hello@junkandhandy.com"
- service_area: "Your Area"
- services: 6 items (Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help)

### Dev Server

- `just dev` — starts singleton dev server on port 4000 (backgrounded, logs to `.dev.log`)
- `just dev-log` — tails the log file
- Health check: `curl http://localhost:4000/`

### Playwright MCP Tools Available

- `browser_navigate` — load URL
- `browser_snapshot` — accessibility tree snapshot
- `browser_resize` — set viewport dimensions
- `browser_run_code` — execute JS in page context
- `browser_take_screenshot` — capture visual state
- `browser_console_messages` — read console output
- `browser_network_requests` — inspect HTTP traffic

## Verification Targets (from ticket)

1. Desktop snapshot: hero (business name, tagline, tel: link), 6 services, "Why Hire Us", footer CTA
2. Mobile snapshot (375x812): all sections present, correct order, no horizontal overflow
3. Server health: no 500 errors in logs

## Constraints

- This is a QA ticket — no code changes expected unless bugs are found
- Playwright MCP operates against the running dev server
- Tests are interactive (agent-driven), not automated test suite
- Failures must be documented with snapshot output and log excerpts
