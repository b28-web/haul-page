# T-005-02 Plan: Gallery Data

## Step 1: Create JSON data files

Create `priv/content/gallery.json` and `priv/content/endorsements.json` with the current hardcoded data, using the ticket AC field names.

Verify: files parse with `Jason.decode!/1`.

## Step 2: Create Haul.Content.Loader module

Create `lib/haul/content/loader.ex` with:
- `load!/0` — reads both JSON files, stores in persistent_term
- `gallery_items/0` — retrieves from persistent_term
- `endorsements/0` — retrieves from persistent_term
- `read_json!/1` — internal helper to read + decode + atomize keys

Verify: module compiles, `mix compile --warnings-as-errors`.

## Step 3: Wire loader into application startup

Add `Haul.Content.Loader.load!()` to `lib/haul/application.ex` `start/2` function.

Verify: `mix phx.server` starts without errors, loader data accessible.

## Step 4: Update ScanLive to use loader

- Remove `@gallery_items` and `@endorsements` module attributes
- Update `mount/3` to call `Haul.Content.Loader.gallery_items()` and `Haul.Content.Loader.endorsements()`
- Update `render/1` template field references to match new field names

Verify: `/scan` page renders identically (same content, same layout).

## Step 5: Update existing tests

Update `test/haul_web/live/scan_live_test.exs`:
- Endorsement name test: read names from `Haul.Content.Loader.endorsements()` instead of hardcoding
- All 8 existing tests should still pass

Verify: `mix test test/haul_web/live/scan_live_test.exs` — 8 tests, 0 failures.

## Step 6: Add loader unit tests

Create `test/haul/content/loader_test.exs`:
- `gallery_items/0` returns non-empty list
- Each gallery item has `:before_photo_url`, `:after_photo_url` keys
- `endorsements/0` returns non-empty list
- Each endorsement has `:customer_name`, `:quote_text` keys
- `star_rating` values are integers 1-5 when present

Verify: `mix test test/haul/content/loader_test.exs` — all pass.

## Step 7: Run full test suite

Verify: `mix test` — all tests pass, no regressions.

## Testing strategy

- **Unit tests** (loader_test.exs): Loader reads files correctly, returns correct shapes
- **Integration tests** (scan_live_test.exs): Scan page renders content from loader
- **No browser tests** — Playwright QA is T-002-04's scope
