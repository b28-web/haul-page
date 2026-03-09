# T-006-04 Research: Content-Driven Pages

## Current Data Flow

### Landing Page (`/`)
- **Controller:** `HaulWeb.PageController.home/2`
- **Template:** `lib/haul_web/controllers/page_html/home.html.heex`
- **Data source:** `Application.get_env(:haul, :operator)` — a keyword list in `config.exs`
- **Assigns:** `@business_name`, `@phone`, `@email`, `@tagline`, `@service_area`, `@coupon_text`, `@services`, `@url`
- **Services:** List of `%{title, description, icon}` maps from operator config
- **Template sections:** Hero (identity), Services grid, Why Hire Us (hardcoded), Footer CTA, Print tear-off coupons

### Scan Page (`/scan`)
- **LiveView:** `HaulWeb.ScanLive`
- **Data source:** `Application.get_env(:haul, :operator)` for identity; `Haul.Content.Loader` for gallery/endorsements
- **Assigns:** `@business_name`, `@phone`, `@service_area`, `@gallery_items`, `@endorsements`
- **Loader:** Reads JSON files from `priv/content/`, caches in `persistent_term` at app startup
- **Gallery items:** Maps with `:before_photo_url`, `:after_photo_url`, `:caption`
- **Endorsements:** Maps with `:customer_name`, `:quote_text`, `:star_rating`, `:date`

### Booking Page (`/book`)
- **LiveView:** `HaulWeb.BookingLive`
- **Data source:** `Application.get_env(:haul, :operator)` for `@phone`, `@business_name`
- **Also uses:** operator `slug` to derive tenant schema name

## Content Ash Resources (target data sources)

All resources use multitenancy via `:context` strategy (schema-per-tenant).

### SiteConfig
- Attributes: `business_name`, `phone`, `email`, `tagline`, `service_area`, `address`, `coupon_text`, `meta_description`, `primary_color`, `logo_url`
- Code interface: `SiteConfig.current()` (read action)
- Single record per tenant

### Service
- Attributes: `title`, `description`, `icon`, `sort_order`, `active`
- Default read sorted by `sort_order` asc
- Multiple records per tenant

### GalleryItem
- Attributes: `before_image_url`, `after_image_url`, `caption`, `alt_text`, `sort_order`, `featured`, `active`
- Note: field names differ from Loader (`before_image_url` vs `before_photo_url`)

### Endorsement
- Attributes: `customer_name`, `quote_text`, `star_rating`, `source`, `date`, `featured`, `active`
- Matches Loader field names

## Content Seeder
- `Haul.Content.Seeder.seed!(tenant)` — idempotent, reads YAML/markdown from `priv/content/`
- Seeds: SiteConfig, Services (6), GalleryItems (3), Endorsements (4), Pages (2)
- Already tested in `seeder_test.exs`

## Key Constraints

1. **Multitenancy:** All Ash reads need a `tenant:` option. Pages must resolve tenant before querying.
2. **Tenant resolution:** Currently `ProvisionTenant.tenant_schema(slug)` where slug comes from operator config.
3. **Fallback requirement:** If DB is empty (no content seeded), pages must render gracefully with fallback copy.
4. **Field name mismatch:** GalleryItem uses `before_image_url`/`after_image_url`; template uses `before_photo_url`/`after_photo_url`.
5. **Loader bridge:** `Haul.Content.Loader` is called at app startup in `Application.start/2`. It must remain functional until fully replaced.
6. **Existing tests:** 6 tests in page_controller_test, 9 in scan_live_test — all rely on operator config or Loader data. Tests need updating.

## Files to Modify
- `lib/haul_web/controllers/page_controller.ex` — query SiteConfig + Services
- `lib/haul_web/live/scan_live.ex` — query GalleryItem + Endorsement + SiteConfig
- `lib/haul_web/live/booking_live.ex` — query SiteConfig for phone/business_name
- `lib/haul_web/controllers/page_html/home.html.heex` — adapt field names if needed
- `test/haul_web/controllers/page_controller_test.exs` — seed content, update assertions
- `test/haul_web/live/scan_live_test.exs` — seed content, update assertions
- `lib/haul/application.ex` — potentially remove Loader.load!() call
- `lib/haul/content/loader.ex` — potentially deprecate/remove
