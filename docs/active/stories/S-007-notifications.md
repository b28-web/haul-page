---
id: S-007
title: notifications
status: open
epics: [E-009, E-006, E-008]
---

## Transactional Notifications (Email + SMS)

Wire up email and SMS delivery so the operator gets notified when a booking comes in, and the customer gets a confirmation.

## Scope

- Swoosh for email (ships with Phoenix, supports Postmark/Resend/Mailgun adapters)
- ExTwilio for SMS (mature Hex package, wraps Twilio REST API)
- Oban workers for async delivery with retries
- Behaviour-based notifier interface so tests use `Swoosh.Adapters.Local` and a fake SMS adapter
- Notification triggers: job created (`:lead`), job state transitions (future)
- Templates: plain-text first, HTML later
