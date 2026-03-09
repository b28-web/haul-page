# T-007-04 Review: Notification Templates

## Summary

Extracted email and SMS template construction from Oban workers into dedicated template modules. Added HTML email variants with inline-styled, operator-branded layout. All acceptance criteria met.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/notifications/booking_email.ex` | `BookingEmail` — builds Swoosh email structs with text + HTML bodies |
| `lib/haul/notifications/booking_sms.ex` | `BookingSMS` — builds SMS message strings |
| `test/haul/notifications/booking_email_test.exs` | 12 unit tests for email templates |
| `test/haul/notifications/booking_sms_test.exs` | 3 unit tests for SMS template |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/workers/send_booking_email.ex` | Replaced inline email construction with `BookingEmail` calls |
| `lib/haul/workers/send_booking_sms.ex` | Replaced inline SMS string with `BookingSMS.operator_alert/1` |

## Test Coverage

- **15 new tests** (12 email + 3 SMS) covering:
  - Correct subject, to, from for both email types
  - Text body contains all expected customer fields
  - HTML body contains all expected customer fields
  - HTML structure (DOCTYPE, tables, headings)
  - Nil handling for optional fields (email, notes)
  - Operator branding in HTML header/footer
  - SMS format and length constraint
- **Existing worker tests** (4 tests) continue to pass — exercise full pipeline through Oban
- **Full suite**: 164 tests, 0 failures

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `Haul.Notifications.BookingEmail` module exists | ✓ |
| Customer confirmation with summary | ✓ |
| Operator alert with name, phone, address, items | ✓ |
| Both plain-text and HTML (inline-styled) | ✓ |
| Operator branding (business name, phone) from config | ✓ |
| SMS operator alert under 160 chars | ✓ |
| Templates tested with ExUnit | ✓ (15 tests) |
| Preview-able in dev via Swoosh mailbox | ✓ (html_body enables rendering at /dev/mailbox) |

## Design Decisions

- **No EEx templates** — used programmatic Swoosh email building with string interpolation. Appropriate for 2 templates; can migrate to EEx if template count grows.
- **HTML escaping** — all user-provided fields are HTML-escaped in the HTML body to prevent injection.
- **Unit tests use plain maps** — no DB or Oban setup needed. Tests are fast and async.
- **"Link to admin" from AC** — not included since no admin UI exists yet. Can be added when admin routes are built.

## Open Concerns

- **No admin link in operator alert** — AC mentions "link to admin" but no admin UI exists. This is a known gap that will resolve when admin routes are built.
- **Email rendering not browser-tested** — HTML email rendering varies across clients. The inline-styled approach is safe for most clients but hasn't been tested in Outlook/Gmail/etc.
- **Long addresses could push SMS over 160 chars** — the template doesn't truncate. For typical US addresses this is fine, but very long addresses could exceed the limit.
