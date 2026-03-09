# T-003-03 Research: Photo Upload

## Existing Booking Flow

**BookingLive** (`lib/haul_web/live/booking_live.ex`):
- Mounts at `/book`, uses `AshPhoenix.Form.for_create(Job, :create_from_online_booking)`
- Form fields: customer_name, customer_phone, customer_email, address, item_description, preferred_dates
- Two states: form view (`@submitted = false`) and confirmation view (`@submitted = true`)
- Validation via `phx-change`, submission via `phx-submit`
- Tenant derived from operator config slug: `"tenant_#{slug}"`

**Job resource** (`lib/haul/operations/job.ex`):
- Ash resource with AshPostgres + AshStateMachine
- Multi-tenancy via `:context` strategy (schema-per-tenant)
- No photo-related attributes exist yet
- Single action: `:create_from_online_booking` accepting all form fields
- State machine starts at `:lead`

**Migration** (`priv/repo/tenant_migrations/20260309005943_create_operations.exs`):
- Creates `jobs` table with all current fields
- No photo columns

## LiveView Upload Mechanism

Phoenix LiveView provides `allow_upload/3` in `mount/3`:
- Configures accepted file types, max entries, max file size
- Returns upload config stored in `socket.assigns.uploads`
- `<.live_file_input upload={@uploads.photos} />` renders the file input
- `handle_event("validate", ...)` automatically validates uploads
- `consume_uploaded_entries/3` in submit handler processes files
- Built-in progress tracking via `entry.progress` (0-100)
- Client-side preview via `entry.client_name` and `entry.ref`
- External upload support: can provide a presigner function for direct-to-S3 uploads

Key `allow_upload` options:
- `accept: ~w(.jpg .jpeg .png .webp .heic)` or `accept: :any`
- `max_entries: 5`
- `max_file_size: 10_000_000` (10MB)
- `auto_upload: true` — uploads start immediately on selection
- `external: &presign_upload/2` — for direct S3 uploads from browser
- `progress: &handle_progress/3` — callback when upload completes

## S3/Tigris Integration Options

**No S3 client in deps.** Current deps include `req ~> 0.5` (HTTP client).

Options:
1. **`ex_aws` + `ex_aws_s3`** — Full-featured S3 client. Well-maintained, widely used.
2. **Direct S3 API via `Req`** — Use AWS Signature V4 manually. More code, fewer deps.
3. **LiveView external uploads** — Browser uploads directly to S3 via presigned URLs. Server generates presigned URL, browser POSTs directly. Most scalable.

Fly Tigris is S3-compatible. Supports standard S3 API operations including presigned URLs.

## Image Storage Pattern in Codebase

`Haul.Content.GalleryItem` stores image URLs as plain strings:
```elixir
attribute :before_image_url, :string, allow_nil?: false, public?: true
attribute :after_image_url, :string, allow_nil?: false, public?: true
```

No upload handling exists yet — gallery items reference URLs but no upload pipeline.

## Testing Infrastructure

- `HaulWeb.ConnCase` with `Phoenix.LiveViewTest` for LiveView tests
- `Haul.DataCase` with Ecto sandbox for DB tests
- Tests create companies + provision tenants in setup, drop schemas in `on_exit`
- 12 existing tests, all passing. BookingLive has rendering, submission, validation tests.
- `Phoenix.LiveViewTest` supports `file_input/4` for testing uploads

## Configuration

- Operator config in `config/config.exs` with runtime overrides in `config/runtime.exs`
- No storage config exists yet
- Secrets deployed via `fly secrets set`

## Constraints

- No Node.js — all assets via Mix tasks (Tailwind + esbuild)
- Mobile-first: camera capture needed (`capture=environment` attribute)
- Dark theme: bg-background (6% lightness), text-foreground (92%)
- Oswald headings, Source Sans 3 body, daisyUI components
- Photos must be optional — form submittable without them
- Max 5 photos per job
- Tenant isolation: S3 keys must include tenant prefix

## Key Files

| File | Role |
|------|------|
| `lib/haul_web/live/booking_live.ex` | Form to modify |
| `lib/haul/operations/job.ex` | Resource to extend |
| `config/runtime.exs` | Storage config to add |
| `mix.exs` | Deps to add |
| `test/haul_web/live/booking_live_test.exs` | Tests to extend |
| `priv/repo/tenant_migrations/` | Migration destination |
