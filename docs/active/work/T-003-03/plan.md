# T-003-03 Plan: Photo Upload

## Step 1: Add deps (mix.exs)

Add `ex_aws`, `ex_aws_s3`, `sweet_xml` to deps. Run `mix deps.get`.

**Verify:** `mix deps.compile` succeeds.

## Step 2: Storage configuration

Add storage backend config to `config/config.exs`, `config/dev.exs`, `config/test.exs`.
Add production S3 config to `config/runtime.exs` (env vars for Tigris).
Add ex_aws config to `config/runtime.exs`.

**Verify:** App compiles with new config.

## Step 3: Storage module

Create `lib/haul/storage.ex` with public API: `put_object/3`, `delete_object/1`, `public_url/1`, `upload_key/3`.
Create `lib/haul/storage/local.ex` — writes to `priv/uploads/`, creates dirs as needed.
Create `lib/haul/storage/s3.ex` — uses ExAws.S3 for put/delete, constructs public URLs.

**Verify:** `mix compile` succeeds.

## Step 4: Storage tests

Create `test/haul/storage_test.exs`:
- Test put_object writes file to priv/uploads/ (local backend)
- Test public_url returns correct path
- Test upload_key generates expected format
- Test delete_object removes file
- Clean up test files in on_exit

**Verify:** `mix test test/haul/storage_test.exs` passes.

## Step 5: Job resource — add photo_urls

Add `photo_urls` attribute (`{:array, :string}`, default `[]`, allow_nil true, public true) to Job resource.
Add `:photo_urls` to the `:create_from_online_booking` action accept list.

Generate migration: `mix ash_postgres.generate_migrations --name add_photo_urls_to_jobs`.

**Verify:** `mix compile` succeeds. Migration file exists.

## Step 6: BookingLive — upload setup

In `mount/3`, add `allow_upload(:photos, accept: ~w(.jpg .jpeg .png .webp .heic), max_entries: 5, max_file_size: 10_000_000)`.

Add `handle_event("cancel-upload", %{"ref" => ref}, socket)` to cancel individual uploads.

**Verify:** `mix compile` succeeds. Existing booking tests still pass.

## Step 7: BookingLive — template changes

Add photo upload section between item_description and preferred dates:
- Label: "Photos of your junk (optional)"
- `<.live_file_input>` with `accept="image/*"` and `capture="environment"`
- Preview grid using `Phoenix.Component.live_img_preview/1`
- Progress bar per entry
- Cancel button per entry
- Error messages for upload validation

Style with dark theme: bg-muted borders, text-foreground labels.

**Verify:** Visual check — form renders with photo upload section.

## Step 8: BookingLive — submit with uploads

Modify `handle_event("submit", ...)`:
1. Consume uploaded entries via `consume_uploaded_entries/3`
2. For each entry, read binary and call `Haul.Storage.put_object/3`
3. Collect returned keys into `photo_urls` list
4. Merge `photo_urls` into form params
5. Submit via `AshPhoenix.Form.submit/2`
6. Wrap storage calls in try/rescue for graceful fallback — if storage fails, submit with empty photo_urls

**Verify:** Full integration test — submit form with photos, verify Job has photo_urls.

## Step 9: Endpoint static serving (dev)

Add `/uploads` to Plug.Static in endpoint for local dev serving.
Create `priv/uploads/.gitkeep`.

**Verify:** Can access uploaded files via browser in dev.

## Step 10: Upload tests

Create `test/haul_web/live/booking_live_upload_test.exs`:
- Photo input renders with correct attributes (accept, capture)
- `file_input/4` with valid image shows preview
- Form submittable without selecting photos
- Max entries enforced (6th file rejected)
- Successful submission with photos creates job with photo_urls

**Verify:** All new tests pass. All existing tests still pass.

## Step 11: Full test suite

Run `mix test` to verify everything passes together.
Run `mix format` and `mix compile --warnings-as-errors`.

**Verify:** Clean test suite, no warnings.

## Testing Strategy

| What | Type | File |
|------|------|------|
| Storage put/delete/url | Unit | `test/haul/storage_test.exs` |
| Upload UI renders | LiveView | `test/haul_web/live/booking_live_upload_test.exs` |
| Upload validation (type, count) | LiveView | same |
| Submit with photos | Integration | same |
| Submit without photos | Integration | existing tests (must not break) |
| Graceful fallback on storage error | Unit | `test/haul/storage_test.exs` |
