# T-005-02 Review: Gallery Data

## Summary

Extracted hardcoded gallery and endorsement data from ScanLive into JSON files in `priv/content/`, loaded by a thin `Haul.Content.Loader` module at application startup. Data structure uses the ticket AC field names, designed to map cleanly to future Ash resources.

## Files created

| File | Purpose |
|------|---------|
| `priv/content/gallery.json` | 3 gallery items (before_photo_url, after_photo_url, caption) |
| `priv/content/endorsements.json` | 4 endorsements (customer_name, quote_text, star_rating, date) |
| `lib/haul/content/loader.ex` | Reads JSON from priv/content/, caches in persistent_term |
| `test/haul/content/loader_test.exs` | 7 unit tests for Loader data shapes |

## Files modified

| File | Change |
|------|--------|
| `lib/haul/application.ex` | Added `Haul.Content.Loader.load!()` call before supervisor start |
| `lib/haul_web/live/scan_live.ex` | Removed 40-line hardcoded data block. Mount reads from Loader. Template field names updated (before_url→before_photo_url, name→customer_name, quote→quote_text, stars→star_rating) |
| `test/haul_web/live/scan_live_test.exs` | Endorsement assertions read from Loader instead of hardcoding names. Added gallery captions test. 8→9 tests. |

## Acceptance criteria verification

- [x] Gallery items configurable: before_photo_url, after_photo_url, caption (optional) — JSON file with these fields
- [x] Endorsements configurable: customer_name, quote_text, star_rating (1-5, optional), date (optional) — JSON file with these fields
- [x] Initial implementation: loaded from JSON file in priv/ — `priv/content/*.json` loaded by Loader
- [x] Data structure maps cleanly to Ash resource later — field names match content-system.md GalleryItem/Endorsement attributes
- [x] Photos served from priv/static/images/ initially — URLs in JSON point to `/images/gallery/` (no actual images yet; placeholder fallback in template)

## Test coverage

| Test file | Count | Coverage |
|-----------|-------|----------|
| `test/haul/content/loader_test.exs` | 7 | gallery_items returns correct shape, endorsements returns correct shape, type constraints on star_rating/caption/date |
| `test/haul_web/live/scan_live_test.exs` | 9 | Page renders, operator data, gallery section, endorsement names from loader, star ratings, captions, footer CTA |
| **Total new/modified** | **16** | All pass |

## Open concerns

1. **No actual gallery images** — `priv/static/images/gallery/` doesn't exist. The template has onerror fallback to icon placeholder. This is expected (images are an operator content concern, not a code concern).

2. **`keys: :atoms` in JSON decode** — Uses `Jason.decode!(keys: :atoms)` which creates atoms from JSON keys. Safe here because the JSON files are developer-controlled (not user input). When migrating to Ash resources, this code gets deleted entirely.

3. **Pre-existing test failure** — `Haul.Accounts.UserTest` "sign in with correct password" fails due to Ash policy authorization issue (no actor set). Unrelated to this ticket. Existed before these changes.

4. **Migration path** — When `Haul.Content` Ash domain lands (T-006-xx):
   - Delete `lib/haul/content/loader.ex`
   - Delete `Haul.Content.Loader.load!()` from application.ex
   - JSON files become seed data for `mix haul.seed_content`
   - ScanLive calls `Ash.read!(Haul.Content.GalleryItem)` instead of `Loader.gallery_items()`
   - Loader tests get replaced with Ash resource tests
