# T-007-03 Plan: Notifier Oban Workers

## Step 1: Oban Configuration

**Files:** config/config.exs, config/test.exs, lib/haul/application.ex

1. Add Oban config to `config/config.exs`: repo, queues (notifications: 10)
2. Add Oban testing config to `config/test.exs`: `testing: :manual`
3. Add `{Oban, ...}` to application supervisor children after Repo
4. Run Oban migration: `mix ecto.gen.migration add_oban_jobs_table` then add Oban migration content
5. Verify: `mix test` still passes (no workers yet, just infrastructure)

## Step 2: Email Worker

**Files:** lib/haul/workers/send_booking_email.ex, test/haul/workers/send_booking_email_test.exs

1. Create `Haul.Workers.SendBookingEmail` with `use Oban.Worker`
2. Implement `perform/1`:
   - Extract job_id and tenant from args
   - Load Job via `Ash.get(Job, job_id, tenant: tenant)`
   - If not found, return :ok (skip)
   - Build operator alert email (always)
   - Build customer confirmation email (if customer_email present)
   - Deliver via `Haul.Mailer.deliver/1`
3. Write tests:
   - Test operator alert sent with correct content
   - Test customer confirmation sent when email present
   - Test customer confirmation skipped when no email
   - Test graceful skip when job not found

## Step 3: SMS Worker

**Files:** lib/haul/workers/send_booking_sms.ex, test/haul/workers/send_booking_sms_test.exs

1. Create `Haul.Workers.SendBookingSMS` with `use Oban.Worker`
2. Implement `perform/1`:
   - Extract job_id and tenant from args
   - Load Job via `Ash.get(Job, job_id, tenant: tenant)`
   - If not found, return :ok
   - Build short SMS: "New booking from {name} — {phone}. {address}"
   - Send via `Haul.SMS.send_sms/3` to operator phone
3. Write tests:
   - Test SMS sent with correct content
   - Test graceful skip when job not found

## Step 4: Ash Change + Integration

**Files:** lib/haul/operations/changes/enqueue_notifications.ex, lib/haul/operations/job.ex, test/haul/operations/changes/enqueue_notifications_test.exs

1. Create `Haul.Operations.Changes.EnqueueNotifications`
2. Implement `after_action/4`: insert both Oban jobs with job_id and tenant
3. Add `change` to `:create_from_online_booking` action in Job resource
4. Write integration test: create job, assert both workers enqueued
5. Run full test suite to verify no regressions

## Testing Strategy

- **Worker unit tests:** Use `Oban.Testing.perform_job/3` to run workers synchronously. Assert emails via `Swoosh.TestAssertions`. Assert SMS via `assert_received {:sms_sent, _}` (Sandbox adapter sends to calling process, and perform_job runs in the test process).
- **Integration test:** Use `Oban.Testing` assertions (`assert_enqueued`) to verify workers are enqueued when a Job is created.
- **All tests use DataCase** with tenant setup (async: false due to multi-tenancy).

## Verification

After all steps: `mix test` passes, including new worker tests and existing booking tests.
