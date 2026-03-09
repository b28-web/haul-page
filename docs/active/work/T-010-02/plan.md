# T-010-02 Plan: Gallery Placeholders

## Step 1: Create gallery image directory

Create `priv/static/images/gallery/`.

## Step 2: Create 6 SVG placeholder files

Create before-{1,2,3}.svg and after-{1,2,3}.svg. Each is a standalone SVG with:
- 800×600 viewBox (matches 4:3 aspect ratio in template)
- Dark background color
- "BEFORE" or "AFTER" text centered
- Simple geometric shapes suggesting clutter (before) or clean space (after)
- Each pair has slightly different accent colors for visual variety

**Verification:** Files exist and are valid SVG (viewable in browser).

## Step 3: Update seed YAML to reference .svg paths

Change all 3 gallery YAML files:
- `.jpg` → `.svg` in both `before_image_url` and `after_image_url`

**Verification:** YAML is valid, paths match created files.

## Step 4: Re-seed and verify

Run `mix haul.seed` to update DB records with new URLs. Then verify:
- No 404 errors for gallery images
- Images are visible on /scan page
- Existing tests still pass

## Testing Strategy

- **Existing tests:** `mix test test/haul_web/live/scan_live_test.exs` — should continue passing (tests check gallery section renders, not image loading)
- **Manual verification:** Load /scan in browser, confirm 6 images visible
- **Browser QA:** Check browser console for 404 errors (deferred to T-010-03 smoke test)
