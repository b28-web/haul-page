# T-003-03 Design: Photo Upload

## Decision: Upload Strategy

### Option A: Server-side upload (LiveView consume_uploaded_entries)
Photos upload to Phoenix server via LiveView channel, server forwards to S3.
- **Pro:** Simple implementation, no presigned URL logic, works offline-first
- **Con:** Server is a bottleneck for large files, uses server memory/bandwidth

### Option B: Direct browser-to-S3 via presigned URLs (external uploads)
Server generates presigned PUT URL, browser uploads directly to Tigris.
- **Pro:** No server bandwidth, scales well, standard S3 pattern
- **Con:** More complex (presigner, CORS config on Tigris), requires S3 client for signing

### Option C: Server-side upload with ex_aws
Same as A but uses ex_aws_s3 for the upload step.
- **Pro:** Full S3 client for future use
- **Con:** Another dep, server still in the data path

**Decision: Option A (server-side upload) with local dev fallback.**

Rationale:
- Photos are small (phone camera, we can limit to 10MB each, 5 max = 50MB worst case)
- Junk removal business gets maybe a few bookings/day — no scale concern
- Simpler to implement and test — no CORS, no presigning
- LiveView's `consume_uploaded_entries` handles the heavy lifting
- For S3 upload, use `Req` (already in deps) with `aws_signature` for signing
- Can upgrade to Option B later if needed without changing the Job resource

**Local dev:** Store to `priv/uploads/` directory. Prod: Tigris S3.

## Decision: S3 Client

### Option A: Add `ex_aws` + `ex_aws_s3`
- **Pro:** Battle-tested, feature-rich
- **Con:** Pulls in many transitive deps (hackney, sweet_xml)

### Option B: Use `Req` + manual AWS Sig V4
- **Pro:** Req already in deps, minimal new deps
- **Con:** More code to maintain, need to handle signing

### Option C: Add lightweight S3 dep
- **Pro:** Purpose-built, fewer deps than ex_aws
- **Con:** Less ecosystem support

**Decision: Option A (ex_aws + ex_aws_s3).**

Rationale:
- Standard choice in Elixir ecosystem for S3
- Will be needed for gallery image uploads later (Content domain)
- Worth the deps to avoid rolling our own S3 signing
- Configure with Tigris endpoint override

## Decision: Photo Storage on Job Resource

### Option A: Array of strings on Job
```elixir
attribute :photo_urls, {:array, :string}, default: []
```
- **Pro:** Simple, Ash handles array attributes well, single column
- **Con:** No per-photo metadata (upload time, original filename)

### Option B: Separate Photo resource with belongs_to Job
- **Pro:** Full metadata, CRUD per photo, can add captions later
- **Con:** Overkill for "customer snaps junk photos", extra migration + resource

### Option C: Array of maps (JSONB)
```elixir
attribute :photo_urls, {:array, :map}, default: []
```
- **Pro:** Metadata without extra table
- **Con:** Harder to validate, query, and type

**Decision: Option A (array of strings).**

Rationale:
- Acceptance criteria says "keys saved on the Job resource" — fits array attribute
- No requirement for per-photo metadata, captions, or individual photo management
- Consistent with how GalleryItem stores URLs (plain strings)
- Array of S3 keys is sufficient: `["tenant_x/jobs/uuid/photo_1.jpg", ...]`

## Decision: S3 Key Structure

Format: `{tenant}/{job_id}/{uuid}.{ext}`

- Tenant prefix ensures isolation
- Job ID groups photos logically
- UUID prevents filename collisions
- Extension preserved for content-type inference

Since the job doesn't exist yet at upload time (photos upload during form fill), we generate a temporary upload prefix and associate it with the job on submission.

Actually — LiveView uploads happen via `consume_uploaded_entries` in the submit handler, which means we can:
1. Submit form → create Job → get job ID → upload photos → save URLs
2. Or: upload to temp prefix → create Job with URLs

**Decision:** Upload in submit handler. Generate a random prefix for the upload path. The submit handler: consume uploads → put to S3 → collect keys → merge into form params → create Job.

Wait — Ash form submission and upload consumption need to be coordinated. Better approach:

1. User selects photos (LiveView validates client-side)
2. User submits form
3. `handle_event("submit", ...)` calls `consume_uploaded_entries` to upload to S3
4. Collect S3 keys into a list
5. Merge `photo_urls` into params
6. Call `AshPhoenix.Form.submit()` with merged params

This way photos upload on submit, and if S3 fails, we can still submit without photos (graceful fallback per AC).

## Decision: Upload UX

- `<.live_file_input>` with `accept="image/*"` and `capture="environment"` for mobile camera
- Show thumbnail previews using `live_img_preview/1` (LiveView built-in)
- Progress bar per photo using `entry.progress`
- Max 5 photos, 10MB each
- `auto_upload: false` — uploads happen on form submit, not on file selection
- Remove button per selected photo (before submit)

## Storage Module

Create `Haul.Storage` module:
- `put_object(key, binary, content_type)` — uploads to configured backend
- `delete_object(key)` — deletes from configured backend
- `public_url(key)` — generates public URL for display
- Backend selection via config: `:local` for dev, `:s3` for prod
- Local backend writes to `priv/uploads/`, serves via Plug.Static

## Config Structure

```elixir
# config/dev.exs
config :haul, :storage, backend: :local

# config/runtime.exs (prod)
config :haul, :storage,
  backend: :s3,
  bucket: System.get_env("STORAGE_BUCKET"),
  region: System.get_env("STORAGE_REGION", "auto"),
  endpoint: System.get_env("STORAGE_ENDPOINT")

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("STORAGE_REGION", "auto")

config :ex_aws, :s3,
  scheme: "https://",
  host: System.get_env("STORAGE_ENDPOINT")
```
