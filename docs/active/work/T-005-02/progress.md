# T-005-02 Progress: Gallery Data

## Completed

- [x] Step 1: Created `priv/content/gallery.json` (3 items) and `priv/content/endorsements.json` (4 items) with ticket AC field names
- [x] Step 2: Created `lib/haul/content/loader.ex` — reads JSON, caches in persistent_term, exposes `gallery_items/0` and `endorsements/0`
- [x] Step 3: Wired `Haul.Content.Loader.load!()` into `lib/haul/application.ex` startup
- [x] Step 4: Updated `lib/haul_web/live/scan_live.ex` — removed hardcoded module attributes, mount reads from Loader, template uses new field names
- [x] Step 5: Updated `test/haul_web/live/scan_live_test.exs` — endorsement names read from Loader, added gallery captions test (9 tests)
- [x] Step 6: Created `test/haul/content/loader_test.exs` — 7 tests covering data shapes, required keys, type constraints
- [x] Step 7: Full test suite — 55 tests, 1 pre-existing failure (user_test sign_in policy issue, unrelated). All 16 gallery/scan tests pass.

## Deviations from plan

None. Implementation followed plan exactly.
