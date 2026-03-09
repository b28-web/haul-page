---
id: T-007-05
story: S-007
title: browser-qa
type: task
status: open
priority: medium
phase: ready
depends_on: [T-007-04]
---

## Context

Automated QA for the notifications story. Notifications are backend-only (email + SMS via Oban workers), so this is a submit-and-verify-side-effects test rather than a pure UI test.

## Test Plan

1. `just dev` — ensure dev server is running
2. Navigate to `http://localhost:4000/book`
3. Submit a valid booking (name, phone, address, description)
4. Verify confirmation page renders
5. Check server logs (`just dev-log 100`) for:
   - Oban worker enqueued for email notification
   - Oban worker enqueued for SMS notification
   - No worker crash/failure logs
6. In dev, verify Swoosh mailbox has the email:
   - Navigate to `http://localhost:4000/dev/mailbox`
   - Snapshot should show booking confirmation email and operator alert email
   - Verify email contains customer name and submitted details

## Acceptance Criteria

- Booking submission triggers notification workers (visible in logs)
- Swoosh dev mailbox shows both customer confirmation and operator alert
- No Oban worker failures in server logs
- SMS sandbox adapter logs the message (visible in dev log)
