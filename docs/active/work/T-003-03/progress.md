# T-003-03 Progress: Photo Upload

## Completed

### Step 1: Add deps
- Added `ex_aws`, `ex_aws_s3`, `sweet_xml` to mix.exs
- `mix deps.get` successful

### Step 2: Storage configuration
- Added `config :haul, :storage, backend: :local` to config.exs
- Added S3/Tigris config to runtime.exs (env var driven)
- Added ex_aws config to runtime.exs

### Step 3: Storage module
- Created `lib/haul/storage.ex` — public API with backend dispatch
- Created `lib/haul/storage/local.ex` — local filesystem backend (priv/static/uploads)
- Created `lib/haul/storage/s3.ex` — S3 backend via ExAws

### Step 4: Storage tests
- Created `test/haul/storage_test.exs` — 7 tests for upload_key, put/delete/url
- All passing

### Step 5: Job resource — add photo_urls
- Added `photo_urls {:array, :string}` attribute (default [], allow_nil true, public true)
- Added `:photo_urls` to `:create_from_online_booking` accept list
- Generated migration: `priv/repo/tenant_migrations/20260309011433_add_photo_urls_to_jobs.exs`

### Step 6: BookingLive — upload setup
- Added `allow_upload(:photos, ...)` in mount with accept, max_entries: 5, max_file_size: 10MB
- Added `handle_event("cancel-upload", ...)` handler

### Step 7: BookingLive — template changes
- Added photo upload section between item_description and preferred dates
- Styled label with camera icon and dashed border
- Preview grid (3 columns) with live_img_preview
- Progress bar per entry
- Cancel button per entry with hero-x-mark icon
- Error messages for upload validation (too_large, too_many_files, not_accepted)
- `live_file_input` hidden inside styled label for custom appearance

### Step 8: BookingLive — submit with uploads
- Modified submit handler to call `consume_uploaded_entries` → `Storage.put_object` per file
- Collects S3 keys, merges into params as `photo_urls`
- Graceful fallback: storage errors return nil, filtered out (form still submits)

### Step 9: Endpoint static serving
- Added `uploads` to `HaulWeb.static_paths()`
- Created `priv/static/uploads/.gitkeep`

### Step 10: Upload tests
- Created `test/haul_web/live/booking_live_upload_test.exs` — 6 tests
- Tests: UI renders, file input present, image acceptance, submit without photos, submit with photos, cancel upload
- All passing

### Step 11: Full test suite
- 128 tests, 0 failures
- `mix compile --warnings-as-errors` clean
- `mix format` clean

## Deviations from Plan

- None. All steps executed as planned.
