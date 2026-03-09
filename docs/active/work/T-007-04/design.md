# T-007-04 Design: Notification Templates

## Decision: Dedicated BookingEmail Module with Swoosh Email Builders

### Approach

Create `Haul.Notifications.BookingEmail` as a pure module that builds `%Swoosh.Email{}` structs. Workers call these functions and pass the result to `Mailer.deliver/1`. SMS template extracted to `Haul.Notifications.BookingSMS`.

### Why This Approach

1. **Separation of concerns** — Workers handle job fetching + error handling + Oban lifecycle. Template modules handle email/SMS construction. Each is testable independently.
2. **Direct Swoosh API** — No EEx, no templating engine. Just functions that return `%Swoosh.Email{}` with both `text_body` and `html_body` set. This is the idiomatic Swoosh pattern.
3. **Testable without Oban** — Template tests don't need database, tenancy, or Oban. Just call the function with a Job struct and assert on the returned email struct.

### Alternatives Rejected

**A) EEx Templates** — Swoosh supports EEx via `Swoosh.Email.render_body/3` but requires Phoenix.View or manual setup. Overkill for 2 email templates. Adds complexity without benefit.

**B) Phoenix.Swoosh with layouts** — Full layout system with partials. Way too heavy for this stage. Could migrate later if template count grows past 5-6.

**C) Keep templates inline in workers** — Simplest, but doesn't satisfy the AC which explicitly asks for a `BookingEmail` module. Also makes testing harder since you need Oban + DB just to test email content.

### HTML Email Design

Simple, inline-styled HTML. No tables-for-layout (modern email clients handle divs). Key decisions:

- **Dark header bar** with business name (matches brand)
- **White content area** with clear sections for customer details
- **Footer** with business name + phone
- All styles inline (email client compatibility)
- Mobile-friendly: max-width 600px, responsive font sizes
- No images, no logos (not available yet)

### SMS Template

Current: `"New booking from {name} — {phone}. {address}"` — already under 160 chars.
Extract to `BookingSMS.operator_alert/1` for consistency, but keep the same format.

### "Link to Admin" in AC

AC says operator alert should include "link to admin." No admin UI exists yet. Include a placeholder URL pattern (`/admin/jobs/{id}`) that will work once admin is built. Use the configured host or a reasonable default.

### Module Structure

```
lib/haul/notifications/
  booking_email.ex    # operator_alert/1, customer_confirmation/1
  booking_sms.ex      # operator_alert/1
```

### Public API

```elixir
# Returns %Swoosh.Email{} with text_body + html_body set
BookingEmail.operator_alert(job)
BookingEmail.customer_confirmation(job)

# Returns string
BookingSMS.operator_alert(job)
```

### Worker Changes

Workers become thin orchestrators:
```elixir
# SendBookingEmail
job |> BookingEmail.operator_alert() |> Mailer.deliver()
job |> BookingEmail.customer_confirmation() |> Mailer.deliver()

# SendBookingSMS
body = BookingSMS.operator_alert(job)
SMS.send_sms(operator[:phone], body)
```

### Test Strategy

- **Unit tests for templates** — No DB, no Oban. Build a fake Job struct, call template functions, assert on returned struct fields (subject, to, from, text_body contains X, html_body contains X).
- **Worker tests** — Keep existing integration tests. They now implicitly test the full pipeline.
- **Swoosh preview** — Setting html_body makes emails render in `/dev/mailbox` automatically.
