# T-006-04 Plan: Content-Driven Pages

## Step 1: Create ContentHelpers module
- Create `lib/haul_web/content_helpers.ex`
- Implement `resolve_tenant/0`, `load_site_config/1`, `load_services/1`, `load_gallery_items/1`, `load_endorsements/1`
- Each function: try Ash.read!, on empty result fall back to operator config or empty list
- Handle case where tenant schema doesn't exist (DB not migrated) by catching errors

## Step 2: Wire PageController to ContentHelpers
- Replace operator config lookup with ContentHelpers calls
- Map SiteConfig struct fields to existing assigns
- Map Service structs to existing assign format (icon, title, description)

## Step 3: Wire ScanLive to ContentHelpers
- Replace operator config + Loader calls with ContentHelpers
- Update template: `item.before_photo_url` -> `item.before_image_url`, `item.after_photo_url` -> `item.after_image_url`

## Step 4: Wire BookingLive to ContentHelpers
- Replace operator config lookup for phone/business_name with ContentHelpers
- Keep tenant resolution for form submission unchanged

## Step 5: Update PageController tests
- Add tenant provisioning + content seeding to setup
- Adjust assertions for seeded data
- Add fallback test (no seeded content → still renders)

## Step 6: Update ScanLive tests
- Add tenant provisioning + content seeding to setup
- Remove Loader references
- Adjust assertions for seeded Ash data
- Add fallback test

## Step 7: Run full test suite
- `mix test` — verify all 128+ tests pass
- Fix any regressions

## Testing Strategy
- Unit: ContentHelpers functions with seeded tenant (fallback and populated cases)
- Integration: Existing page_controller_test and scan_live_test with seeded content
- Regression: Full suite to ensure no breakage
