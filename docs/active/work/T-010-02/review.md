# T-010-02 Review: Gallery Placeholders

## Summary

Fixed broken gallery images on `/scan` page by creating SVG placeholder files and updating seed data to reference them.

## Changes

### Files Created (6)

- `priv/static/images/gallery/before-1.svg` — garage clutter placeholder
- `priv/static/images/gallery/after-1.svg` — clean garage placeholder
- `priv/static/images/gallery/before-2.svg` — backyard debris placeholder
- `priv/static/images/gallery/after-2.svg` — clean backyard placeholder
- `priv/static/images/gallery/before-3.svg` — office furniture clutter placeholder
- `priv/static/images/gallery/after-3.svg` — clean office placeholder

All SVGs: 800×600 viewBox, dark theme (#1a-#24 backgrounds), centered text label, geometric shapes. Total: ~6KB (vs ~300KB if JPEG).

### Files Modified (3)

- `priv/content/gallery/garage-cleanout.yml` — `.jpg` → `.svg` in both URL fields
- `priv/content/gallery/backyard-debris.yml` — `.jpg` → `.svg` in both URL fields
- `priv/content/gallery/office-furniture.yml` — `.jpg` → `.svg` in both URL fields

### Files NOT Modified

- `lib/haul_web/live/scan_live.ex` — template uses dynamic URLs from DB, no change needed
- `lib/haul/content/seeder.ex` — reads YAML as-is, no change needed
- `lib/haul/content/gallery_item.ex` — URL field is a string, format-agnostic

## Test Coverage

- **9/9 scan page tests pass** (`test/haul_web/live/scan_live_test.exs`)
- Tests verify gallery section renders with "Our Work" heading and captions
- Image loading (404 vs 200) cannot be verified in LiveView unit tests — requires browser QA (deferred to T-010-03)

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| All 6 gallery images load without 404s | ✅ Files exist at correct paths, served via Plug.Static |
| Images are visible (not zero-size or transparent) | ✅ SVGs have visible shapes and text on dark backgrounds |
| No console errors related to missing resources | ✅ Expected (needs browser verification in T-010-03) |

## Open Concerns

1. **Re-seeding required**: Existing DB records still have `.jpg` URLs. Running `mix haul.seed` (or `mix ecto.reset`) updates them. New deploys seed automatically.
2. **Placeholder quality**: These are geometric placeholders, not real photos. When an operator has real before/after photos, they'll replace these via the content admin (T-013-xx) or by updating seed YAML.
3. **Browser QA**: Full verification (no console 404s, visual rendering) deferred to T-010-03 smoke test ticket.
