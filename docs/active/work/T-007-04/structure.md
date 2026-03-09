# T-007-04 Structure: Notification Templates

## New Files

### `lib/haul/notifications/booking_email.ex`

Module: `Haul.Notifications.BookingEmail`

Public functions:
- `operator_alert(job :: %Job{}) :: %Swoosh.Email{}`
  - to: operator email from config
  - from: operator email from config
  - subject: "New booking from {customer_name}"
  - text_body: structured plain text with all customer fields
  - html_body: inline-styled HTML with header, detail sections, footer

- `customer_confirmation(job :: %Job{}) :: %Swoosh.Email{}`
  - to: job.customer_email
  - from: operator email from config
  - subject: "Booking received — {business_name}"
  - text_body: greeting, summary, "we'll contact you" message
  - html_body: inline-styled HTML matching operator alert style

Private helpers:
- `operator_config/0` — reads `:haul, :operator` config
- `html_layout/2` — wraps content in branded HTML shell (header + footer)

### `lib/haul/notifications/booking_sms.ex`

Module: `Haul.Notifications.BookingSMS`

Public functions:
- `operator_alert(job :: %Job{}) :: String.t()`
  - Returns: "New booking from {name} — {phone}. {address}"
  - Must stay under 160 characters

### `test/haul/notifications/booking_email_test.exs`

Module: `Haul.Notifications.BookingEmailTest`

Tests:
- operator_alert returns email with correct subject, to, from
- operator_alert text_body contains customer_name, phone, email, address, item_description
- operator_alert html_body contains same fields wrapped in HTML
- customer_confirmation returns email with correct subject, to, from
- customer_confirmation text_body contains greeting, address, items
- customer_confirmation html_body contains same fields
- operator branding (business name, phone) appears in both templates

### `test/haul/notifications/booking_sms_test.exs`

Module: `Haul.Notifications.BookingSMSTest`

Tests:
- operator_alert contains customer name, phone, address
- operator_alert is under 160 characters for typical input

## Modified Files

### `lib/haul/workers/send_booking_email.ex`

Changes:
- Remove inline email construction (lines 23-72)
- Add alias for `Haul.Notifications.BookingEmail`
- Replace `send_operator_alert/1` with: `job |> BookingEmail.operator_alert() |> Mailer.deliver()`
- Replace `send_customer_confirmation/1` with: guard on email presence, then `job |> BookingEmail.customer_confirmation() |> Mailer.deliver()`

### `lib/haul/workers/send_booking_sms.ex`

Changes:
- Add alias for `Haul.Notifications.BookingSMS`
- Replace inline string with: `BookingSMS.operator_alert(job)`

## Unchanged Files

- `lib/haul/mailer.ex` — no changes needed
- `config/*.exs` — no changes needed
- `test/haul/workers/*_test.exs` — existing tests continue to pass (same behavior, different code path)
- `lib/haul/operations/job.ex` — no changes

## Directory Layout After

```
lib/haul/notifications/
  booking_email.ex
  booking_sms.ex
test/haul/notifications/
  booking_email_test.exs
  booking_sms_test.exs
```
