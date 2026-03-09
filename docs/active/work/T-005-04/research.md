# T-005-04 Research — Browser QA for Scan Page

## Ticket Summary

Automated browser QA for the scan page (`/scan`). Verify QR-code landing page renders correctly using Playwright MCP. Depends on T-005-03 (QR generation) which is complete.

## Scan Page Architecture

**Route:** `GET /scan` → `HaulWeb.ScanLive` (LiveView, not controller-rendered)
**QR Route:** `GET /scan/qr` → `HaulWeb.QRController, :generate`

The scan page is a read-only LiveView with no interactive state. It loads operator config from `Application.get_env(:haul, :operator)` and content data from `Haul.Content.Loader` (persistent_term cache). Template is inline ~H sigil.

## Page Sections (top to bottom)

### 1. Hero/CTA Section
- Eyebrow: operator business name (uppercase, tracking-widest)
- H1: "Scan to Schedule" (6xl→8xl responsive)
- Phone number as oversized `tel:` link (5xl→7xl, Oswald font)
  - Strips non-digit chars for tel: URI: `(555) 123-4567` → `tel:+5551234567`
- "Book Online" button linking to `/book` (route doesn't exist yet — expected 404)

### 2. Before/After Gallery
- H2: "Our Work"
- 3 gallery items from `priv/content/gallery.json`
- Each: 2-column grid (before | after), aspect-[4/3], lazy loading
- onerror fallback: hides broken img, shows hero-photo icon
- **Images do NOT exist** in `priv/static/images/gallery/` — fallback will trigger

### 3. Customer Endorsements
- H2: "What Customers Say"
- 4 endorsements from `priv/content/endorsements.json`
- Star rating (1-5, hero-star-solid/hero-star icons)
- Quote text in curly quotes, customer name

### 4. Footer/Ready to Book
- H2: "Ready to Book?"
- Two CTAs: Call (filled) + Book Online (outlined)
- Footer tagline: "{business_name} · {service_area}"

## Operator Config

Source: `config/config.exs`
- `business_name`: "Junk & Handy"
- `phone`: "(555) 123-4567"
- `email`: "hello@junkandhandy.com"
- `service_area`: "Your Area"

## Content Data

- `priv/content/gallery.json` — 3 items (before_photo_url, after_photo_url, caption)
- `priv/content/endorsements.json` — 4 items (customer_name, quote_text, star_rating, date)
- Loaded by `Haul.Content.Loader.load!()` at app startup, cached in `:persistent_term`

## Existing Test Coverage

- `test/haul_web/live/scan_live_test.exs` — 9 tests (structure, content, links)
- `test/haul_web/controllers/qr_controller_test.exs` — 10 tests (format, size, headers)
- `test/haul/content/loader_test.exs` — 7 tests (data structure validation)
- Total: 26 tests, all passing

## Key Files

| File | Role |
|------|------|
| `lib/haul_web/live/scan_live.ex` | Scan page LiveView |
| `lib/haul_web/controllers/qr_controller.ex` | QR generation endpoint |
| `lib/haul/content/loader.ex` | JSON content loader |
| `priv/content/gallery.json` | Gallery data |
| `priv/content/endorsements.json` | Endorsement data |
| `config/config.exs` | Operator config |

## QA-Relevant Observations

1. **Gallery images missing** — URLs reference `/images/gallery/before-1.jpg` etc. but no files exist. The onerror handler provides a graceful fallback (photo icon placeholder).
2. **`/book` route doesn't exist** — CTA buttons will 404. Expected; T-003-01 creates it.
3. **No touch/swipe gallery** — Vertical scroll only, no carousel.
4. **Dark theme** — Pure grayscale via CSS custom properties. Consistent with landing page.
5. **Mobile-first responsive** — Phone number and CTA should be prominent on 375px viewport.
6. **Fonts** — Oswald for headings, Source Sans 3 for body. Loaded from Google Fonts.

## Constraints

- Dev server must be running (`just dev` or `mix phx.server`)
- Playwright MCP available via `.mcp.json`
- No database required — scan page is read-only with JSON content
