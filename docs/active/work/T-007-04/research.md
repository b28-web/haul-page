# T-007-04 Research: Notification Templates

## Current State

### Email Construction (Workers)

`lib/haul/workers/send_booking_email.ex` builds emails inline using `Swoosh.Email`:
- **Operator alert**: plain-text only, subject "New booking from {name}", includes customer details
- **Customer confirmation**: plain-text only, subject "Booking received — {business}", summary + "we'll contact you"
- No HTML variant for either email
- No dedicated template module — email bodies are string interpolations inside worker functions

`lib/haul/workers/send_booking_sms.ex` builds SMS inline:
- Single line: `"New booking from {name} — {phone}. {address}"` (already under 160 chars)

### Operator Config

`Application.get_env(:haul, :operator, [])` provides:
- `:business_name` — "Junk & Handy" (default)
- `:phone` — "(555) 123-4567"
- `:email` — "hello@junkandhandy.com"
- Runtime overridable via env vars in `config/runtime.exs`

### Job Resource Fields (Available for Templates)

From `lib/haul/operations/job.ex`:
- `customer_name` (required string)
- `customer_phone` (required string)
- `customer_email` (optional string)
- `address` (required string)
- `item_description` (required string)
- `preferred_dates` (optional list of dates, default [])
- `notes` (optional string)
- `photo_urls` (optional list of strings, default [])

### Swoosh Infrastructure

- `Haul.Mailer` — `use Swoosh.Mailer, otp_app: :haul`
- Dev: `Swoosh.Adapters.Local` with mailbox at `/dev/mailbox`
- Test: `Swoosh.Adapters.Test` with `Swoosh.TestAssertions`
- Prod: Postmark or Resend via runtime env vars

### Test Patterns

Existing worker tests in `test/haul/workers/`:
- Use `Haul.DataCase, async: false` + `Oban.Testing`
- Create a Company + tenant + Job in setup
- Use `perform_job/2` to execute workers
- Assert with `assert_email_sent(subject: ...)` and `assert_received {:sms_sent, message}`
- Cleanup: drop tenant schemas in `on_exit`

### What the Ticket Asks For

1. `Haul.Notifications.BookingEmail` module with:
   - Customer confirmation email (plain-text + HTML)
   - Operator alert email (plain-text + HTML)
   - Operator branding from runtime config
2. SMS templates (already inline in worker, needs extraction)
3. Tests asserting subject, to/from, body content
4. Preview-able in dev via Swoosh mailbox viewer (already works with Local adapter)

### Key Observations

- The workers currently own email construction AND delivery. The ticket wants to extract construction into a dedicated `BookingEmail` module.
- SMS construction is a single line — extraction is minimal but keeps the pattern consistent.
- HTML emails need inline styles (no CSS framework per AC). Simple table-based or div-based layout.
- The Swoosh mailbox viewer at `/dev/mailbox` already renders HTML emails — adding `html_body/2` to the Swoosh.Email struct is all that's needed for preview.
- Preferred dates and photo URLs are available but not currently included in templates.
- No "link to admin" exists yet (no admin UI), but AC mentions it for operator alert.

### Files to Modify

- `lib/haul/workers/send_booking_email.ex` — delegate to BookingEmail module
- `lib/haul/workers/send_booking_sms.ex` — delegate to template function
- New: `lib/haul/notifications/booking_email.ex` — template module
- New: `test/haul/notifications/booking_email_test.exs` — unit tests for templates
- Existing worker tests may need updates if assertions change

### Constraints

- No EEx templates — Swoosh uses programmatic email building
- HTML must use inline styles (no external CSS, no framework)
- SMS under 160 chars
- Must work with Swoosh mailbox viewer (just needs html_body set)
