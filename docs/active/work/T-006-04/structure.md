# T-006-04 Structure: Content-Driven Pages

## New Files

### `lib/haul_web/content_helpers.ex`
Module: `HaulWeb.ContentHelpers`

Public functions:
- `resolve_tenant/0` — returns tenant schema string from operator config slug
- `load_site_config/1` — takes tenant, returns SiteConfig struct or fallback map
- `load_services/1` — takes tenant, returns list of Service structs or fallback list
- `load_gallery_items/1` — takes tenant, returns list of GalleryItem structs or empty list
- `load_endorsements/1` — takes tenant, returns list of Endorsement structs or empty list

Each function wraps Ash.read! with rescue/fallback to operator config or empty data.

## Modified Files

### `lib/haul_web/controllers/page_controller.ex`
- Remove `Application.get_env(:haul, :operator)` lookup
- Call `ContentHelpers.resolve_tenant/0`
- Call `ContentHelpers.load_site_config/1` and `ContentHelpers.load_services/1`
- Assign from SiteConfig struct fields and services list

### `lib/haul_web/live/scan_live.ex`
- Remove `Application.get_env(:haul, :operator)` lookup
- Remove `Haul.Content.Loader` calls
- Call `ContentHelpers` for tenant, site_config, gallery_items, endorsements
- Update template field references: `before_photo_url` -> `before_image_url`, `after_photo_url` -> `after_image_url`

### `lib/haul_web/live/booking_live.ex`
- Replace operator config lookup for `@phone` and `@business_name` with `ContentHelpers`
- Keep existing tenant resolution for form submission (already correct)

### `lib/haul_web/controllers/page_html/home.html.heex`
- No changes needed — assigns come from controller, field names stay the same

### `test/haul_web/controllers/page_controller_test.exs`
- Add setup: provision tenant, seed content
- Update assertions to verify content comes from seeded data
- Add test: empty DB renders gracefully (fallback copy)

### `test/haul_web/live/scan_live_test.exs`
- Add setup: provision tenant, seed content
- Remove references to `Haul.Content.Loader`
- Update assertions for seeded data
- Add test: empty DB renders gracefully

## Unchanged Files
- `lib/haul/content/*.ex` — Ash resources stay as-is
- `lib/haul/content/seeder.ex` — already complete
- `lib/haul_web/controllers/page_html/home.html.heex` — no field name changes needed
- `config/config.exs` — operator config stays as fallback
