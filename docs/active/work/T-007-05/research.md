# T-007-05 Research — Browser QA for Notifications

## Ticket Scope

Automated browser QA for the notifications story (S-007). Notifications are backend-only (email + SMS via Oban workers), so this is a submit-and-verify-side-effects test — submit a booking in the browser, then verify that notification workers ran and emails appeared in the Swoosh dev mailbox.

## Notification Pipeline Architecture

```
BookingLive (/book) → form submit
  → AshPhoenix.Form.submit → Job.create_from_online_booking
  → EnqueueNotifications (Ash change, after_action)
    → Oban.insert(SendBookingEmail worker)
    → Oban.insert(SendBookingSMS worker)

SendBookingEmail (Oban worker, :notifications queue)
  → Loads Job from DB
  → Sends operator alert email (always)
  → Sends customer confirmation email (if customer_email present)

SendBookingSMS (Oban worker, :notifications queue)
  → Loads Job from DB
  → Sends SMS to operator phone via Haul.SMS
```

## Key Files

| File | Role |
|------|------|
| `lib/haul_web/live/booking_live.ex` | Booking form LiveView at `/book` |
| `lib/haul/operations/job.ex` | Job Ash resource, `:create_from_online_booking` action |
| `lib/haul/operations/changes/enqueue_notifications.ex` | Ash change hook that enqueues Oban workers |
| `lib/haul/workers/send_booking_email.ex` | Email delivery Oban worker |
| `lib/haul/workers/send_booking_sms.ex` | SMS delivery Oban worker |
| `lib/haul/notifications/booking_email.ex` | Email templates (operator_alert, customer_confirmation) |
| `lib/haul/notifications/booking_sms.ex` | SMS templates |
| `lib/haul/mailer.ex` | Swoosh mailer, `Swoosh.Adapters.Local` in dev |
| `lib/haul/sms.ex` | SMS behavior dispatcher |
| `lib/haul/sms/sandbox.ex` | Dev/test SMS adapter (logs to Logger) |
| `lib/haul_web/router.ex` | `/dev/mailbox` route (Swoosh MailboxPreview) |
| `config/config.exs` | Oban config, operator email/phone/business defaults |

## Dev Environment Behavior

- **Email adapter:** `Swoosh.Adapters.Local` — stores emails in-memory, viewable at `/dev/mailbox`
- **SMS adapter:** `Haul.SMS.Sandbox` — logs to Logger, no external call
- **Oban:** Normal queue processing (not `:manual` like in test env)
- **Tenant:** `ContentHelpers.resolve_tenant()` returns default tenant

## Swoosh Dev Mailbox

Route: `forward "/dev/mailbox", Plug.Swoosh.MailboxPreview` (guarded by `dev_routes: true`)

The mailbox UI shows all emails sent during the dev session. After a booking submission, we should see:
1. **Operator alert** — "New booking from {customer_name}" sent to operator email
2. **Customer confirmation** — "Booking confirmed" sent to customer email (only if email was provided in form)

## Form Fields (Required for Submission)

| Field | Type | Required | Test Value |
|-------|------|----------|------------|
| `customer_name` | text | yes | "QA Test Customer" |
| `customer_phone` | tel | yes | "555-0199" |
| `customer_email` | email | no | "qa-test@example.com" |
| `address` | text | yes | "456 QA Test Ave" |
| `item_description` | textarea | yes | "Notification QA test items" |

Including `customer_email` is important — it triggers the customer confirmation email in addition to the operator alert.

## Prior Browser QA Pattern

Established by T-002-04, T-005-04, T-003-04:
- Playwright MCP against live dev server (`just dev` on localhost:4000)
- Navigate, snapshot, interact, verify
- Results documented in progress.md
- Screenshots optional but helpful
- Bug fixes applied inline if trivial

## What's Different About This QA

Previous QAs tested visible UI behavior. This ticket tests **side effects** — the UI action (booking submit) triggers backend workers whose output appears in a different page (`/dev/mailbox`) and in server logs. The verification flow:

1. Submit booking at `/book` → see confirmation screen (UI part)
2. Navigate to `/dev/mailbox` → verify emails arrived (backend verification)
3. Check server logs for SMS sandbox output and no Oban failures

## Risks

- **Oban timing:** Workers run async. Short delay between submission and email appearance. May need a brief wait before checking mailbox.
- **Swoosh mailbox state:** Accumulates all emails from the dev session. Need to identify the specific emails from our test submission, not prior ones.
- **Tenant setup:** Dev server needs a working tenant with schema. If no tenant exists, the booking form may error. The `just dev` setup should handle this.
- **Database state:** Each QA run creates a real Job record. Acceptable for dev testing.
