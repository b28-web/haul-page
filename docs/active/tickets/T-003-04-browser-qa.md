---
id: T-003-04
story: S-003
title: browser-qa
type: task
status: open
priority: high
phase: done
depends_on: [T-003-03]
---

## Context

Automated browser QA for the booking form story. Use Playwright MCP to verify the booking flow end-to-end — form renders, validates, submits, and creates a Job.

## Test Plan

1. `just dev` — ensure dev server is running
2. Navigate to `http://localhost:4000/book`
3. Verify form fields present via snapshot:
   - Name, phone, email, address, item description, preferred dates
   - Photo upload input
   - Submit button
4. Test validation — submit empty form:
   - Snapshot should show validation error messages
   - No server 500 in `just dev-log`
5. Fill form with valid test data using `browser_fill_form` / `browser_type`:
   - Name: "Test Customer"
   - Phone: "555-0100"
   - Address: "123 Test St"
   - Item description: "Old couch removal"
6. Submit the form
7. Verify confirmation page/message appears in snapshot
8. Check server logs — Job created in `:lead` state (look for relevant log line)
9. Mobile viewport (375x812): repeat form render check — fields usable, no overflow

## Acceptance Criteria

- Full booking flow completes without error
- Validation errors display for empty/invalid submissions
- Confirmation shown after successful submit
- No 500 errors in server logs
