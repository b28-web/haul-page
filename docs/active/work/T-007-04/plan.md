# T-007-04 Plan: Notification Templates

## Step 1: Create BookingEmail module

Create `lib/haul/notifications/booking_email.ex` with:
- `operator_alert/1` — builds Swoosh email with text_body + html_body
- `customer_confirmation/1` — builds Swoosh email with text_body + html_body
- Private `operator_config/0` helper
- Private `html_layout/2` for consistent HTML wrapper

Verify: module compiles (`mix compile`)

## Step 2: Create BookingSMS module

Create `lib/haul/notifications/booking_sms.ex` with:
- `operator_alert/1` — returns formatted SMS string

Verify: module compiles

## Step 3: Write BookingEmail tests

Create `test/haul/notifications/booking_email_test.exs`:
- Build a fake job struct (no DB needed — just a map or struct with required fields)
- Test operator_alert: subject, to, from, text_body content, html_body content
- Test customer_confirmation: subject, to, from, text_body content, html_body content
- Test operator branding appears in templates

Verify: `mix test test/haul/notifications/booking_email_test.exs`

## Step 4: Write BookingSMS tests

Create `test/haul/notifications/booking_sms_test.exs`:
- Test operator_alert contains expected fields
- Test message length under 160 chars

Verify: `mix test test/haul/notifications/booking_sms_test.exs`

## Step 5: Refactor workers to use template modules

Modify `send_booking_email.ex`:
- Replace inline email construction with BookingEmail calls
- Keep Oban worker structure, error handling, customer_email guard

Modify `send_booking_sms.ex`:
- Replace inline SMS string with BookingSMS.operator_alert/1 call

Verify: `mix test test/haul/workers/` — existing worker tests still pass

## Step 6: Run full test suite

`mix test` — all tests pass, no regressions

## Testing Strategy

- **Unit tests (new)**: Template modules tested with plain structs, no DB/Oban
- **Integration tests (existing)**: Worker tests exercise full pipeline through Oban
- **Manual verification**: HTML emails visible at `/dev/mailbox` in dev server
