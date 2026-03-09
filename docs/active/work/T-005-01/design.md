# T-005-01 Design: Scan Page Layout

## Decision: LiveView with Hardcoded Data, No App Layout

### Key Decisions

#### 1. LiveView Module Structure

**Chosen:** Single `ScanLive` module at `lib/haul_web/live/scan_live.ex` with inline `render/1`.

**Rationale:** The scan page is a single page with no sub-routes or actions. A `scan_live/index.ex` + `index.html.heex` split is overkill for a page with no forms or complex interactions. When the gallery becomes interactive (swipeable), we can extract the template then.

**Rejected:** `ScanLive.Index` in a subdirectory — unnecessary nesting for a single page.

#### 2. Layout Strategy

**Chosen:** Use root layout (provides CSS/JS/theme script), skip app layout via `layout: {HaulWeb.Layouts, :root}` — but actually root is already the default for LiveView. The app layout wrapping is controlled by whether we render inside `<.app>` or not.

Actually: LiveView pages use root layout automatically. The app layout (`app.html.heex`) wraps `@inner_content` and includes a navbar. For the scan page, we don't want the navbar. We'll set `layout: false` in the LiveView to skip the app layout, same pattern as the landing page. The root layout still applies.

Wait — in Phoenix 1.8, LiveView layout works differently. The `put_root_layout` in the router pipeline sets the root layout. The `layout` option in the LiveView module sets the "app" layout. Setting `layout: false` in the LiveView skips the app layout but keeps the root layout.

**Chosen:** `use Phoenix.LiveView, layout: false` — renders inside root layout only (no navbar).

#### 3. Data Strategy

**Chosen:** Hardcode gallery and endorsements as module attributes in `ScanLive`.

**Rationale:** No Ash resources exist yet. Config file (`config.exs`) could work but adds noise to a file that's already loaded with operator identity. Module attributes keep the data co-located with the only consumer. When Ash resources land (T-006-xx), we swap `@gallery_items` for `Ash.read!(GalleryItem)`.

**Rejected:**
- Config-based: Mixes presentation data with operator identity config
- Separate data module: Over-abstraction for hardcoded placeholder data

#### 4. Gallery Section Design

**Chosen:** Side-by-side before/after pairs in a vertical scroll. Each pair is a card with two images side by side, a caption below. On mobile: images stack or use a compact side-by-side with smaller images. No swipe carousel initially — just vertical scroll.

**Rationale:** A swipe carousel requires JS hooks and touch event handling. The ticket says "swipeable on mobile" but the MVP is vertical scroll with side-by-side pairs. We can add swipe via a LiveView JS hook in T-005-02 or T-005-03. The data structure supports it — each item has before/after URLs.

**Image approach:** Use placeholder images from `priv/static/images/gallery/`. These will be simple colored rectangles or placeholder images since no real photos exist yet. The template uses `<img>` tags with `loading="lazy"` for below-fold items.

#### 5. Endorsements Section Design

**Chosen:** Card-based layout. Each endorsement shows customer name, quote text, and optional star rating (rendered as filled/empty star icons). Grid layout: single column on mobile, two columns on desktop.

**Rationale:** Matches the visual density of the landing page's "Why Hire Us" section. Stars use `hero-star` (filled) and `hero-star` with reduced opacity (empty) from Heroicons.

#### 6. CTA Section Design

**Chosen:** Prominent hero section at top with:
- Operator business name
- "Scan to Schedule" heading (large, Oswald)
- Phone number as oversized `tel:` link (same style as landing page)
- "Book Online" CTA button linking to `/book`

**Rationale:** Someone who scanned a QR code is curious but uncommitted. The phone number and book button must be immediately visible without scrolling. Copy the landing page's phone number styling for consistency.

#### 7. Test Approach

**Chosen:** LiveView tests using `live(conn, "/scan")` assertions. Test:
- Page mounts and renders 200
- Operator name and phone visible
- Phone is a tel: link
- Book CTA links to `/book`
- Gallery section renders with image pairs
- Endorsements section renders with names and quotes
- Star ratings render correctly

### Visual Structure (Top to Bottom)

```
┌─────────────────────────────────┐
│          JUNK & HANDY           │  ← operator name (eyebrow)
│      SCAN TO SCHEDULE           │  ← h1, Oswald, huge
│                                 │
│    Call for a free estimate      │
│       (555) 123-4567            │  ← tel: link, oversized
│                                 │
│    ┌───────────────────────┐    │
│    │     BOOK ONLINE →     │    │  ← CTA button → /book
│    └───────────────────────┘    │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│        OUR WORK                 │  ← h2
│                                 │
│  ┌──────────┬──────────┐        │
│  │  BEFORE  │  AFTER   │        │  ← image pair
│  └──────────┴──────────┘        │
│  Caption text here              │
│                                 │
│  ┌──────────┬──────────┐        │
│  │  BEFORE  │  AFTER   │        │  ← image pair
│  └──────────┴──────────┘        │
│  Caption text here              │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│     WHAT CUSTOMERS SAY          │  ← h2
│                                 │
│  ┌─────────────────────────┐    │
│  │ ★★★★★                   │    │
│  │ "Great service, fast    │    │
│  │  and professional."     │    │
│  │          — Jane D.      │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ ★★★★☆                   │    │
│  │ "Showed up on time..."  │    │
│  │          — Mike R.      │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│      READY TO BOOK?             │  ← footer CTA
│   Call or book online today.    │
│                                 │
│  ┌─────────┐  ┌────────────┐   │
│  │  CALL   │  │ BOOK ONLINE│   │
│  └─────────┘  └────────────┘   │
└─────────────────────────────────┘
```

### Tradeoffs

| Choice | Benefit | Cost |
|--------|---------|------|
| Inline render/1 | Simple, single file | Harder to read if template grows |
| Module attr data | Co-located, easy to swap | Not config-overridable |
| No swipe carousel | No JS hooks needed | Less polished mobile UX |
| Placeholder images | Can ship without real photos | Looks incomplete |
| Skip app layout | Clean full-page design | Must set layout explicitly |
