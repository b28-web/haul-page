---
id: T-007-03
story: S-007
title: notifier-oban
type: task
status: open
priority: high
phase: done
depends_on: [T-007-01, T-007-02, T-003-01]
---

## Context

Notifications must be async and retryable. Define Oban workers that send email and SMS when a Job enters `:lead` state. The workers use the Swoosh mailer and SMS behaviour set up in prior tickets.

## Acceptance Criteria

- `Haul.Workers.SendBookingEmail` Oban worker — sends confirmation to customer + alert to operator
- `Haul.Workers.SendBookingSMS` Oban worker — sends SMS alert to operator phone number
- Workers enqueued by an Ash change on the `:create_from_online_booking` action (or via AshOban)
- Retries configured: max 3 attempts, exponential backoff
- Email template: plain-text with customer name, phone, address, item description
- SMS template: short message with customer name and link to admin (or phone number)
- Tests verify workers enqueue correctly and execute with Sandbox/Test adapters
- Failed deliveries are logged and visible in Oban dashboard (if mounted)
