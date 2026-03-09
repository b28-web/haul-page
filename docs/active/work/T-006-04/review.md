# T-006-04 Review: Content-Driven Pages

## Summary

Wired the landing page, scan page, and booking page to read from Ash content resources (SiteConfig, Service, GalleryItem, Endorsement) instead of hardcoded operator config. Pages fall back to operator config when no content is seeded.

## Files Changed

### New
- `lib/haul_web/content_helpers.ex` — shared module for tenant resolution and content queries with fallback

### Modified
- `lib/haul_web/controllers/page_controller.ex` — reads SiteConfig + Services from Ash
- `lib/haul_web/live/scan_live.ex` — reads SiteConfig + GalleryItem + Endorsement from Ash; updated field names to match Ash resource attributes
- `lib/haul_web/live/booking_live.ex` — reads SiteConfig from Ash for phone/business_name
- `test/haul_web/controllers/page_controller_test.exs` — provisions tenant, seeds content, verifies Ash-driven data
- `test/haul_web/live/scan_live_test.exs` — provisions tenant, seeds content, removes Loader references
- `priv/content/services/*.yml` — added `hero-` prefix to icon names (6 files)

### Not Modified (unchanged)
- `lib/haul/content/*.ex` — Ash resources unchanged
- `lib/haul/content/loader.ex` — kept for backward compatibility (still called at app startup)
- `lib/haul/application.ex` — Loader.load!() call retained
- `config/config.exs` — operator config retained as fallback source

## Test Coverage

- **135 tests, 0 failures** (up from 128)
- Page controller: 8 tests covering business identity, tel/mailto links, services, sections, coupon text
- Scan live: 9 tests covering identity, gallery, endorsements, star ratings, CTA sections
- Booking live: 6 tests (unchanged, still pass)
- Content seeder: 5 tests (unchanged, still pass — icon prefix fix needed for `hero-` convention match)

## Acceptance Criteria Verification

| Criterion | Status |
|---|---|
| Landing page reads SiteConfig and Services from Ash | Done |
| Service grid renders from `@services` assign | Done |
| Business name, phone, tagline, email, service area from `@site_config` | Done |
| Scan page reads GalleryItems and Endorsements from Ash | Done |
| Gallery renders from `@gallery_items`, endorsements from `@endorsements` | Done |
| Footer tear-off tabs read coupon text from SiteConfig | Done |
| Empty DB pages render gracefully with fallback copy | Done — falls back to operator config |
| No visual regression | Done — same assigns, same template structure |

## Open Concerns

1. **`get_field/2` duplication** — PageController, ScanLive, and BookingLive each have a private `get_field/2` helper. Could be extracted to ContentHelpers but left private to avoid coupling modules to a utility function for a 2-line helper.

2. **Loader not removed** — `Haul.Content.Loader` is still called at app startup and its module exists. Nothing references it anymore (ScanLive was the only consumer). Safe to remove in a cleanup pass.

3. **Seeder test count assertions** — The seeder test expects 6 services. If seed files are added/removed, the test will need updating. This is pre-existing.

4. **Tenant schema cleanup in tests** — Tests drop all `tenant_%` schemas on exit. If tests run in parallel, they could interfere. Tests are marked `async: false` to prevent this.

5. **No active filter in Ash queries** — ContentHelpers filters `active` in Elixir rather than in the Ash query. For small datasets this is fine; for larger datasets, an Ash filter would be more efficient. Could add a filtered read action later.
