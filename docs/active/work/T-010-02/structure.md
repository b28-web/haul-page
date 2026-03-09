# T-010-02 Structure: Gallery Placeholders

## Files Created

### `priv/static/images/gallery/before-1.svg`
### `priv/static/images/gallery/before-2.svg`
### `priv/static/images/gallery/before-3.svg`

SVG placeholders (800×600, dark bg, "BEFORE" text, scattered box shapes suggesting clutter).

### `priv/static/images/gallery/after-1.svg`
### `priv/static/images/gallery/after-2.svg`
### `priv/static/images/gallery/after-3.svg`

SVG placeholders (800×600, slightly lighter bg, "AFTER" text, clean/empty space).

## Files Modified

### `priv/content/gallery/garage-cleanout.yml`
- `before_image_url`: `/images/gallery/before-1.jpg` → `/images/gallery/before-1.svg`
- `after_image_url`: `/images/gallery/after-1.jpg` → `/images/gallery/after-1.svg`

### `priv/content/gallery/backyard-debris.yml`
- `before_image_url`: `/images/gallery/before-2.jpg` → `/images/gallery/before-2.svg`
- `after_image_url`: `/images/gallery/after-2.jpg` → `/images/gallery/after-2.svg`

### `priv/content/gallery/office-furniture.yml`
- `before_image_url`: `/images/gallery/before-3.jpg` → `/images/gallery/before-3.svg`
- `after_image_url`: `/images/gallery/after-3.jpg` → `/images/gallery/after-3.svg`

## Files NOT Modified

- `lib/haul_web/live/scan_live.ex` — no changes needed, template uses dynamic URLs from DB
- `lib/haul/content/seeder.ex` — no changes needed, reads YAML as-is
- `lib/haul/content/gallery_item.ex` — no changes needed, URL is just a string

## Ordering

1. Create directory and SVG files
2. Update seed YAML files
3. Verify (re-seed DB, check /scan page)
