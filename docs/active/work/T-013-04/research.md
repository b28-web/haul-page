# T-013-04 Gallery Manager — Research

## Ticket Summary

Build `/app/content/gallery` LiveView for operators to manage before/after photo gallery: upload, caption, reorder, delete. Gallery appears on scan page.

## Existing Codebase

### GalleryItem Resource (`lib/haul/content/gallery_item.ex`)

Ash resource in Content domain with:
- **Attributes:** `before_image_url` (required), `after_image_url` (required), `caption`, `alt_text`, `sort_order` (int, default 0), `featured` (bool), `active` (bool)
- **Actions:** `:add` (create), `:edit` (update — caption, alt_text, sort_order, featured, active), `:read`, `:destroy`
- **Multi-tenancy:** `:context` strategy (schema-per-tenant)
- **Audit:** AshPaperTrail with `:changes_only`
- **Note:** `:edit` does NOT accept image URL changes — images are immutable once uploaded

### Storage Module (`lib/haul/storage.ex`)

- `put_object(key, binary, content_type)` → `{:ok, key}` or `{:error, reason}`
- `delete_object(key)` → `:ok` or `{:error, reason}`
- `public_url(key)` → URL string
- `upload_key(tenant, prefix, filename)` → `"#{tenant}/#{prefix}/#{uuid}#{ext}"`
- Backends: `:local` (dev, `priv/static/uploads`) and `:s3` (prod, Tigris)

### Existing Upload Pattern (`lib/haul_web/live/booking_live.ex`)

BookingLive uses Phoenix LiveView uploads:
- `allow_upload(:photos, accept: ~w(.jpg .jpeg .png .webp .heic), max_entries: 5, max_file_size: 10_000_000)`
- `consume_uploaded_entries` to read binary and call `Storage.put_object`
- `cancel_upload` for removing entries before submit
- Preview via `<.live_img_preview entry={entry} />`
- Error display via `upload_errors/1,2` + `friendly_error/1`

### Admin Layout (`lib/haul_web/components/layouts/admin.html.heex`)

- Sidebar with nav links (Dashboard, Content, Bookings, Settings)
- Content link highlights for `/app/content*` paths
- Auth via `HaulWeb.AuthHooks :require_auth` — provides `@current_user`, `@current_company`, `@current_path`

### Router (`lib/haul_web/router.ex`)

Authenticated admin routes at `/app/*`:
- `live_session :authenticated` with admin layout
- Existing: `/app/content/site` → `App.SiteConfigLive`
- Gallery route NOT yet added — need `live "/content/gallery", App.GalleryLive`

### Reference CRUD Pattern (`lib/haul_web/live/app/site_config_live.ex`)

Single-resource form pattern:
- Mount: resolve tenant from `current_company.slug`, load existing data, `assign_form`
- AshPhoenix.Form for create/update with `phx-change="validate"` + `phx-submit="save"`
- Flash messages for success/error

### Scan Page Gallery Display (`lib/haul_web/live/scan_live.ex`)

- Loads via `ContentHelpers.load_gallery_items(tenant)` — filters active items
- Renders before/after side-by-side in grid, lazy loading, captions
- Changes to gallery items should be immediately visible here

### Content Helpers (`lib/haul_web/content_helpers.ex`)

- `load_gallery_items(tenant)` — reads all, filters `active == true`
- No sorting applied (reads default order) — need `sort_order` ordering

### Tests (`test/haul/content/gallery_item_test.exs`)

- Basic CRUD tests: create with valid attrs, require image URLs, edit caption/featured
- Setup creates company + provisions tenant, cleanup drops tenant schemas
- Test helper: `ConnCase.create_authenticated_context/1` for auth context

## Constraints & Observations

1. **No image processing deps** — ticket says "resize/optimize on upload" but no image processing library exists (no `mogrify`, `image`, or `vix`). Must either add a dep or defer optimization.
2. **Before/after model** — GalleryItem requires BOTH before AND after image URLs. Upload UX needs to handle paired images.
3. **No drag-to-reorder JS hook** — ticket wants drag-to-reorder but no sortable JS library exists. Will need a JS hook with SortableJS or similar.
4. **5MB limit in ticket** vs 10MB in existing upload code. Ticket specifies 5MB max.
5. **`:edit` action doesn't accept image URLs** — images can't be swapped after creation, only metadata changes.
6. **No image deletion from storage** — `Storage.delete_object` exists but no code currently calls it. Destroying a GalleryItem should clean up stored files.
7. **Content helpers don't sort** — `load_gallery_items` returns items without respecting `sort_order`. Scan page will need sorting too.
