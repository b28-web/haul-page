# T-007-05 Design — Browser QA for Notifications

## Approach

Interactive Playwright MCP testing against the live dev server, following the established pattern from T-002-04, T-005-04, and T-003-04. The unique aspect: verifying backend side effects (emails in Swoosh mailbox, SMS in logs) triggered by a browser form submission.

## Options Considered

### Option A: Playwright MCP interactive tests (CHOSEN)

- Submit booking via Playwright, then navigate to `/dev/mailbox` to verify emails
- Check server logs for SMS sandbox output and Oban worker success
- **Pros:** Tests the full end-to-end flow, matches prior QA pattern, verifies real browser + backend integration
- **Cons:** Requires dev server running, creates real DB records, async timing may need a short wait

### Option B: Extend existing unit/integration tests

- Add more tests to `test/haul/workers/` or `test/haul/notifications/`
- **Pros:** Automated, repeatable, CI-friendly
- **Cons:** Workers and notifications already have 164 tests with good coverage. This ticket specifically calls for browser QA — verifying the end-to-end path from UI to notification delivery.

### Option C: Curl/API-based submission + log inspection

- Use `curl` to POST to the booking endpoint, then check logs
- **Pros:** Simple, no Playwright needed
- **Cons:** Doesn't test the LiveView form (which uses `phx-submit`), misses the UI layer entirely. LiveView forms use WebSocket, not HTTP POST.

**Decision:** Option A. The ticket explicitly requires browser-based QA. The existing test suite covers unit/integration; this covers the last mile — real browser interaction triggering real backend side effects.

## Test Sequence

1. **Navigate to `/book`** — verify form loads
2. **Fill form with test data** — include email to trigger customer confirmation
3. **Submit** — verify confirmation screen ("Thank You!")
4. **Wait briefly** — allow Oban workers to process (1-2 seconds)
5. **Navigate to `/dev/mailbox`** — verify notification emails appeared
6. **Inspect emails** — verify operator alert and customer confirmation content
7. **Check server logs** — verify SMS sandbox logged the message, no Oban failures

## Email Verification Expectations

After submitting a booking with `customer_email` provided:

| Email | To | Subject Pattern | Content Checks |
|-------|----|----------------|----------------|
| Operator alert | hello@junkandhandy.com | "New booking from QA Test Customer" | Customer name, phone, address, description |
| Customer confirmation | qa-test@example.com | "Booking confirmed" | Business name, confirmation text |

## SMS Verification

The SMS Sandbox adapter logs via `Logger.info`. In dev server logs we expect:
```
[info] [SMS Sandbox] Sending to +15551234567: New booking from QA Test Customer — 555-0199. 456 QA Test Ave
```

## Bug Handling

- Document findings in progress.md
- Fix trivial issues inline (e.g., missing assigns, template typos)
- Log complex issues as blockers in review.md for separate tickets

## Artifacts

- Results documented in progress.md
- Final assessment in review.md
