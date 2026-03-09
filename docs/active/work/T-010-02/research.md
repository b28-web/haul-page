# T-010-02 Research: Gallery Placeholders

## Problem

The `/scan` page gallery section references 6 images that don't exist, causing 404s and falling back to hero-photo icons.

## Data Flow

```
priv/content/gallery/*.yml  (seed data, 3 files)
  → Seeder.seed_gallery_items/1 reads YAML, creates GalleryItem records
  → ScanLive.mount/3 loads via ContentHelpers.load_gallery_items(tenant)
  → Template renders <img src={item.before_image_url} ...>
  → Browser requests /images/gallery/before-1.jpg → 404
  → onerror handler hides img, shows hero-photo icon placeholder
```

## Files Involved

### Seed YAML (source of image URLs)

- `priv/content/gallery/garage-cleanout.yml` — before-1.jpg, after-1.jpg
- `priv/content/gallery/backyard-debris.yml` — before-2.jpg, after-2.jpg
- `priv/content/gallery/office-furniture.yml` — before-3.jpg, after-3.jpg

All reference `/images/gallery/{before,after}-{1,2,3}.jpg`.

### Static Assets

- `priv/static/images/` exists, contains only `logo.svg`
- `priv/static/images/gallery/` does NOT exist
- No image files exist at the referenced paths

### Template (scan_live.ex)

Lines 72-73, 89-90: `<img src={item.before_image_url} ...>` — uses URL from DB record directly.
Lines 77, 94: `onerror` handler hides broken img, shows fallback icon.

### Seeder (lib/haul/content/seeder.ex)

Lines 75-101: `seed_gallery_items/1` globs `priv/content/gallery/*.yml`, reads YAML, creates/updates GalleryItem records. Matches on `before_image_url` for upsert.

### GalleryItem Resource

`lib/haul/content/gallery_item.ex` — Ash resource with `before_image_url`, `after_image_url` (both :string, required), plus caption, alt_text, sort_order, featured, active.

## Constraints

- Image src attributes come from DB via seed YAML — not hardcoded in template
- The `<img>` tag works with any format the browser can render (jpg, png, svg, webp)
- Seed YAML currently specifies `.jpg` extension
- Phoenix serves `priv/static/` at `/` via Plug.Static (configured in endpoint.ex)
- Template has graceful fallback (onerror) but the acceptance criteria require actual visible images

## Test Coverage

`test/haul_web/live/scan_live_test.exs` — tests gallery section renders with "Our Work" heading and captions. Does not verify image loading (can't in unit tests).
