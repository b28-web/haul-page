# T-005-01 Review: Scan Page Layout

## Summary

Built the `/scan` LiveView page — a QR code landing page for junk removal operators. Three content sections (hero CTA, before/after gallery, customer endorsements) plus a footer CTA. Mobile-first, dark grayscale theme matching the landing page.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/live/scan_live.ex` | LiveView module with hardcoded gallery/endorsement data and inline template |
| `test/haul_web/live/scan_live_test.exs` | 8 LiveView tests covering all acceptance criteria |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added `live "/scan", ScanLive` route to browser scope |

## What Was Built

### Hero Section
- Operator business name as eyebrow text
- "Scan to Schedule" h1 heading (Oswald, 6xl/8xl responsive)
- Phone number as oversized `tel:` link
- "Book Online" CTA button linking to `/book`

### Before/After Gallery
- "Our Work" heading
- 3 hardcoded before/after image pairs with labels and captions
- Side-by-side layout (2-column grid per pair)
- `loading="lazy"` on images
- Graceful fallback: `onerror` handler hides broken img, shows photo icon placeholder

### Customer Endorsements
- "What Customers Say" heading
- 4 hardcoded endorsements with star ratings (rendered as `hero-star-solid` / `hero-star` icons)
- Quote text, customer name
- Grid layout: 1 column mobile, 2 columns desktop

### Footer CTA
- "Ready to Book?" heading
- Call button (filled) + Book Online button (outlined)
- Operator name and service area tagline

## Test Coverage

8 tests, all passing. Coverage:

| Test | What it verifies |
|------|-----------------|
| Page renders | LiveView mounts at `/scan` with 200 |
| Business name | Operator config data flows to template |
| Phone tel: link | Phone number rendered as clickable tel: link |
| Book Online CTA | Link to `/book` present |
| Gallery section | "Our Work" heading, Before/After labels |
| Endorsements | All 4 customer names rendered |
| Star ratings | `hero-star-solid` icons present |
| Footer CTA | "Ready to Book?" section present |

**Full suite: 23 tests, 0 failures, no regressions.**

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| Route `GET /scan` serves a LiveView page | ✅ |
| Top section: operator name, heading, phone tel: link, CTA to /book | ✅ |
| Middle section: before/after photo gallery, side-by-side pairs | ✅ |
| Bottom section: customer endorsements with star rating | ✅ |
| Same dark theme and typography as landing page | ✅ |
| Mobile-first | ✅ |
| Gallery and endorsements driven by config (hardcoded initially) | ✅ |

### Partially Met

- **Swipeable on mobile** — Not implemented. Gallery uses vertical scroll with side-by-side pairs. Swipe carousel would require JS hooks (future ticket).

## Open Concerns

1. **No real images exist** — Gallery references `/images/gallery/before-*.jpg` and `after-*.jpg` which don't exist in `priv/static/images/`. The template has `onerror` fallbacks that show a photo icon placeholder. Real images need to be added or the paths need to be updated to point to placeholder image URLs.

2. **`/book` route doesn't exist yet** — The CTA buttons link to `/book` which will 404. This is expected — T-003-01 (booking form) creates that route. No workaround needed.

3. **Swipe carousel deferred** — The ticket mentions "swipeable on mobile" for the gallery. This requires a JS hook (touch event handling or a library). Could be added in T-005-02 or T-005-03.

4. **First LiveView page** — This establishes the pattern for all future LiveView pages. The pattern is: module in `lib/haul_web/live/`, reads operator config in `mount/3`, inline `render/1`, no app layout (renders directly in root layout). Future LiveViews (booking form, admin) should follow this pattern unless they need the app layout navbar.

5. **No print stylesheet** — Unlike the landing page, the scan page has no `@media print` overrides. This is intentional — the scan page is exclusively a phone experience (QR code scanning). No print support needed.

## Architecture Notes for Other Agents

- The `live` directory is now established at `lib/haul_web/live/`. Future LiveView modules go here.
- Test directory `test/haul_web/live/` is also established.
- Gallery and endorsement data will migrate to Ash resources (`Haul.Content.GalleryItem`, `Haul.Content.Endorsement`) when T-006-xx content system tickets land. The module attribute pattern (`@gallery_items`, `@endorsements`) is the thing to replace.
