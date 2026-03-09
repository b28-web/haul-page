# T-006-04 Progress: Content-Driven Pages

## Completed Steps

### Step 1: ContentHelpers module
- Created `lib/haul_web/content_helpers.ex`
- Functions: `resolve_tenant/0`, `load_site_config/1`, `load_services/1`, `load_gallery_items/1`, `load_endorsements/1`
- Each function queries Ash resources with graceful fallback to operator config or empty list

### Step 2: PageController wired
- Replaced `Application.get_env(:haul, :operator)` with ContentHelpers calls
- Added `get_field/2` helper to handle both Ash structs and plain maps uniformly

### Step 3: ScanLive wired
- Replaced operator config + `Haul.Content.Loader` calls with ContentHelpers
- Updated field names: `before_photo_url` → `before_image_url`, `after_photo_url` → `after_image_url`
- Added `:if` guards on gallery and endorsement sections for graceful empty-state rendering
- Added nil safety for `@phone` in `String.replace` calls
- Added nil guard on `star_rating` before rendering star icons

### Step 4: BookingLive wired
- Replaced operator config lookup for `@phone` and `@business_name` with ContentHelpers
- Kept existing tenant resolution for form submission

### Step 5: Seed data fix
- Updated service YAML files in `priv/content/services/` to use `hero-` prefix for icon names
- Required because `<.icon>` component expects `hero-*` names

### Step 6: Tests updated
- `page_controller_test.exs`: provisions tenant, seeds content, verifies data comes from Ash
- `scan_live_test.exs`: provisions tenant, seeds content, queries Ash resources for assertions
- Both tests use `async: false` for DDL operations and clean up tenant schemas on exit

### Step 7: Full suite verification
- 135 tests, 0 failures (up from 128)

## Deviations from Plan
- Added `get_field/2` private helper to PageController, ScanLive, and BookingLive to handle Access protocol difference between Ash structs and plain maps
- Fixed service seed YAML files to include `hero-` prefix (not anticipated in plan)
- Did not create a separate ContentHelpers test file — behavior is tested via integration tests
