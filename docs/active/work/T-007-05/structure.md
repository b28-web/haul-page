# T-007-05 Structure — Browser QA for Notifications

## Overview

This is a QA-only ticket — no code changes unless bugs are found. The "structure" is the test procedure, not code architecture.

## Test Procedure Components

### Component 1: Booking Submission (Browser)

**Target:** `http://localhost:4000/book`
**Actions:**
- Navigate to page
- Snapshot to verify form loaded
- Fill required fields (name, phone, address, description) + optional email
- Submit form
- Snapshot confirmation screen

**Files involved (read-only):**
- `lib/haul_web/live/booking_live.ex` — form template and event handlers
- `lib/haul/operations/job.ex` — action triggered on submit

### Component 2: Email Verification (Browser)

**Target:** `http://localhost:4000/dev/mailbox`
**Actions:**
- Navigate to Swoosh mailbox preview
- Snapshot to see email list
- Identify operator alert and customer confirmation emails
- Verify email subjects and recipients

**Files involved (read-only):**
- `lib/haul/notifications/booking_email.ex` — email template definitions
- `lib/haul/mailer.ex` — Swoosh adapter config

### Component 3: Log Verification (Server)

**Target:** Dev server stdout/logs
**Actions:**
- Check for SMS sandbox log line
- Check for Oban worker completion (no failures)

**Files involved (read-only):**
- `lib/haul/sms/sandbox.ex` — Logger.info output format
- `lib/haul/workers/send_booking_email.ex` — worker success path
- `lib/haul/workers/send_booking_sms.ex` — worker success path

## Files Created

| File | Purpose |
|------|---------|
| `docs/active/work/T-007-05/research.md` | Codebase mapping |
| `docs/active/work/T-007-05/design.md` | Approach decision |
| `docs/active/work/T-007-05/structure.md` | This file |
| `docs/active/work/T-007-05/plan.md` | Step-by-step test procedure |
| `docs/active/work/T-007-05/progress.md` | Test execution results |
| `docs/active/work/T-007-05/review.md` | Final assessment |

## Files Modified

None expected unless bugs are found during QA.

## Dependencies

- Dev server must be running (`just dev`)
- Playwright MCP must be available
- Database must have a working tenant (default from `ContentHelpers.resolve_tenant()`)
