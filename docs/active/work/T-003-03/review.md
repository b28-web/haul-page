# T-003-03 Review: Photo Upload

## Summary

Added photo upload capability to the booking form. Customers can select up to 5 photos (JPG, PNG, WebP, HEIC) which upload on form submission via LiveView's `allow_upload` mechanism. Photos are stored via a configurable storage backend (local filesystem for dev/test, S3-compatible for production via Fly Tigris). The form remains fully submittable without photos.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/storage.ex` | Storage abstraction — dispatches to local or S3 backend |
| `lib/haul/storage/local.ex` | Local filesystem backend (priv/static/uploads) |
| `lib/haul/storage/s3.ex` | S3 backend via ExAws (Fly Tigris in production) |
| `test/haul/storage_test.exs` | 7 unit tests for storage module |
| `test/haul_web/live/booking_live_upload_test.exs` | 6 LiveView upload tests |
| `priv/repo/tenant_migrations/20260309011433_add_photo_urls_to_jobs.exs` | Migration adding photo_urls column |
| `priv/static/uploads/.gitkeep` | Placeholder for local upload directory |

## Files Modified

| File | Change |
|------|--------|
| `mix.exs` | Added ex_aws, ex_aws_s3, sweet_xml deps |
| `config/config.exs` | Added `:storage` config (backend: :local default) |
| `config/runtime.exs` | Added S3/Tigris config from env vars |
| `lib/haul/operations/job.ex` | Added `photo_urls` attribute, updated action accept list |
| `lib/haul_web/live/booking_live.ex` | Added upload handling, photo UI section, submit integration |
| `lib/haul_web.ex` | Added `uploads` to static_paths |

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| `input[type=file][accept="image/*"][capture=environment]` | Partial | accept uses specific extensions (.jpg,.jpeg,.png,.webp,.heic). `capture` attribute not added — see open concern below. |
| Multiple photos (up to 5) | Done | `max_entries: 5` in allow_upload |
| LiveView `allow_upload` with progress | Done | Progress bar per entry in UI |
| Upload to S3-compatible (Tigris) | Done | S3 backend configured, env-var driven |
| Graceful fallback if upload fails | Done | Storage errors return nil, filtered out |
| Preview thumbnails after upload | Done | `live_img_preview` shows preview immediately on selection |

## Test Coverage

- **Storage module:** 7 tests — upload_key generation, put/delete/url operations, edge cases
- **Upload UI:** 6 tests — rendering, file input, image acceptance, submit with/without photos, cancel
- **Existing booking tests:** 15 tests still passing (no regressions)
- **Full suite:** 128 tests, 0 failures

## Open Concerns

1. **`capture="environment"` attribute:** The AC specifies this HTML attribute to open the camera on mobile. LiveView's `live_file_input` component doesn't support arbitrary HTML attributes. The `accept` constraint in `allow_upload` ensures only images are selectable, and on mobile devices the OS will offer camera as a source for `image/*` types. However, adding `capture=environment` would require either (a) wrapping the live_file_input with a custom component that adds the attribute, or (b) adding it via a JS hook. This is a minor UX enhancement — the current implementation works on mobile but doesn't force camera-first. If this is critical, a follow-up to add a JS hook that sets the attribute on mount would solve it.

2. **S3 public URL format:** The S3 backend generates URLs as `https://{bucket}.{host}/{key}`. This assumes the Tigris bucket has public read access configured. If the bucket is private, URLs would need to be presigned. For customer-uploaded junk photos this is likely fine as public, but worth confirming during deployment.

3. **No image resizing/compression:** Uploaded images are stored as-is. On mobile, photos can be 3-5MB each. No server-side or client-side compression is applied. If bandwidth becomes a concern, client-side compression via a JS hook or server-side processing (e.g., libvips/Image) could be added later.

4. **Local storage in priv/static:** For dev/test, files are written to `priv/static/uploads/`. This directory is served by Plug.Static and excluded from live_reload patterns. The `.gitkeep` ensures the directory exists. Files accumulate in dev — no cleanup mechanism.

5. **No migration run:** The generated migration exists but hasn't been applied to the dev or test databases. Running `mix ecto.migrate` will apply it. Tests auto-migrate via the test alias.

## Architecture Notes for Other Agents

- **`Haul.Storage` is the public API** for file storage across the app. Future tickets (gallery uploads, content images) should use this module rather than building their own.
- **Backend selection** is config-driven: `:local` or `:s3`. No code changes needed to switch.
- **S3 keys include tenant prefix** for isolation: `{tenant}/jobs/{uuid}.{ext}`.
- **The `photo_urls` attribute** stores raw S3 keys (not full URLs). Use `Haul.Storage.public_url/1` to get displayable URLs.
