# T-005-01 Plan: Scan Page Layout

## Step 1: Create ScanLive Module

Create `lib/haul_web/live/scan_live.ex` with:

1. Module attributes for hardcoded gallery items (3-4 entries with before/after image paths, captions)
2. Module attributes for hardcoded endorsements (4-5 entries with name, quote, star rating)
3. `mount/3` — read operator config, assign data to socket
4. `render/1` — full page template with four sections

Template sections:
- **Hero:** operator name eyebrow text, "Scan to Schedule" h1 (text-6xl md:text-8xl), phone as oversized tel: link, "Book Online" CTA button
- **Gallery:** "Our Work" heading, before/after image pairs in a vertical list, each with labels and caption
- **Endorsements:** "What Customers Say" heading, quote cards with star ratings, grid layout (1-col mobile, 2-col desktop)
- **Footer CTA:** "Ready to Book?" heading, call button + book online button side by side

Style requirements:
- Match landing page's dark theme (bg-background, text-foreground)
- Oswald for headings (auto via base styles), Source Sans 3 for body
- Mobile-first responsive breakpoints
- `<main>` wrapper with same classes as landing page

**Verify:** `mix compile` succeeds

## Step 2: Add Route

Add `live "/scan", ScanLive` to the browser scope in `lib/haul_web/router.ex`.

**Verify:** `mix compile` succeeds, dev server shows page at `/scan`

## Step 3: Create Tests

Create `test/haul_web/live/scan_live_test.exs` with tests for:

1. Page mounts successfully (200 response)
2. Displays operator business name
3. Displays phone number as tel: link
4. Contains "Scan to Schedule" heading
5. Contains "Book Online" link to `/book`
6. Contains "Our Work" gallery section
7. Contains endorsement customer names
8. Contains star rating elements

**Verify:** `mix test` — all tests pass

## Step 4: Verify Full Suite

Run `mix test` to confirm no regressions. Run `mix format` and `mix credo` for code quality.

**Verify:** All tests pass, no format/credo warnings

## Testing Strategy

| What | Type | Verification |
|------|------|-------------|
| Page renders at /scan | LiveView mount test | `live(conn, "/scan")` returns `{:ok, view, html}` |
| Operator data displayed | Content assertion | `assert html =~ business_name` |
| Phone is tel: link | HTML structure | `assert html =~ "tel:"` |
| CTA links to /book | Navigation | `assert html =~ ~s(href="/book")` |
| Gallery renders | Content assertion | `assert html =~ "Our Work"` |
| Endorsements render | Content assertion | `assert html =~ customer_name` |
| No regressions | Full suite | `mix test` passes |
