# T-007-03 Review: Notifier Oban Workers

## Summary

Implemented async notification workers that send email and SMS when a booking is created. Workers are enqueued automatically via an Ash change on the `:create_from_online_booking` action.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/workers/send_booking_email.ex` | Oban worker — sends operator alert + customer confirmation emails |
| `lib/haul/workers/send_booking_sms.ex` | Oban worker — sends operator SMS with booking details |
| `lib/haul/operations/changes/enqueue_notifications.ex` | Ash Change — enqueues both workers after job creation |
| `priv/repo/migrations/*_add_oban_jobs_table.exs` | Oban v12 migration |
| `test/haul/workers/send_booking_email_test.exs` | 3 tests: operator alert, customer confirmation, job-not-found |
| `test/haul/workers/send_booking_sms_test.exs` | 2 tests: operator SMS, job-not-found |
| `test/haul/operations/changes/enqueue_notifications_test.exs` | 1 test: both workers enqueued on job creation |

## Files Modified

| File | Change |
|------|--------|
| `config/config.exs` | Added Oban config (repo, notifications queue with 10 concurrency) |
| `config/test.exs` | Added `Oban, testing: :manual` |
| `lib/haul/application.ex` | Added Oban to supervision tree after Repo |
| `lib/haul/operations/job.ex` | Added `change EnqueueNotifications` to `:create_from_online_booking` |

## Test Coverage

- **6 new tests**, all passing
- **145 total tests**, 0 failures (no regressions)
- Worker tests use `Oban.Testing.perform_job/3` for synchronous execution
- Email assertions via `Swoosh.TestAssertions` (Test adapter)
- SMS assertions via `assert_received {:sms_sent, _}` (Sandbox adapter)
- Integration test uses `assert_enqueued` to verify worker insertion

## Acceptance Criteria Status

| Criteria | Status |
|----------|--------|
| `SendBookingEmail` Oban worker | Done |
| `SendBookingSMS` Oban worker | Done |
| Workers enqueued by Ash change on `:create_from_online_booking` | Done |
| Retries: max 3, exponential backoff | Done (Oban default backoff) |
| Email: plain-text with customer name, phone, address, items | Done |
| SMS: short message with customer name and phone | Done |
| Tests verify enqueue and execution | Done |
| Failed deliveries logged/visible in Oban | Done (Oban stores failed jobs in oban_jobs table) |

## Design Decisions

1. **Ash Change (not LiveView hook):** Notifications fire from the domain layer, ensuring any code path that creates a Job triggers notifications — not just the booking form.
2. **Separate workers:** Email and SMS are independent. One failing doesn't block the other.
3. **Minimal args:** Workers receive `job_id` + `tenant`, load fresh data. No stale serialized data.
4. **Graceful not-found:** If a job is deleted between enqueue and execution, workers return `:ok` and skip.

## Open Concerns

- **No Oban dashboard mounted.** The Oban Web UI is a paid product. Failed jobs are visible in the `oban_jobs` table directly. A future ticket could add `Oban.Web` if licensed, or a simple admin view.
- **Email templates are inline strings.** T-007-04 (notification-templates) may extract these into proper template modules. Current plain-text is functional and meets the AC.
- **SMS Sandbox sends to calling process.** In production Oban workers run in their own processes, so test assertions work via `perform_job` (synchronous in test process). This is correct behavior.
