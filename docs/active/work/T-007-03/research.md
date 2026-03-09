# T-007-03 Research: Notifier Oban Workers

## Dependencies (all satisfied)

- **T-007-01 (swoosh-setup):** `Haul.Mailer` at `lib/haul/mailer.ex` — uses `Swoosh.Mailer, otp_app: :haul`. Adapters: Local (dev), Test (test), Postmark/Resend (prod via runtime.exs). Dev mailbox at `/dev/mailbox`.
- **T-007-02 (sms-client):** `Haul.SMS` at `lib/haul/sms.ex` — behaviour with `send_sms/3`. Adapters: Sandbox (dev/test, sends `{:sms_sent, msg}` to caller), Twilio (prod).
- **T-003-01 (job-resource):** `Haul.Operations.Job` at `lib/haul/operations/job.ex` — Ash resource with `:create_from_online_booking` action. Fields: customer_name, customer_phone, customer_email, address, item_description, preferred_dates, notes, photo_urls.

## Oban / AshOban Status

- `ash_oban ~> 0.7.2` in mix.exs (line 76). Pulls in `oban` transitively. Both in mix.lock.
- **No Oban config exists yet** — not in config.exs, test.exs, or runtime.exs.
- **No Oban supervisor** in `Haul.Application` children list.
- **No existing workers** — no `lib/haul/workers/` directory.

## Application Supervisor

`lib/haul/application.ex` — children: Telemetry, Repo, DNSCluster, PubSub, Endpoint. Oban must be added before Endpoint.

## Booking LiveView Integration Point

`lib/haul_web/live/booking_live.ex:43-45` — after `AshPhoenix.Form.submit` succeeds with `{:ok, _job}`, currently just sets `submitted: true`. This is the hook point for enqueuing notification workers.

## Operator Config

`config.exs` lines 17-57 — `:haul, :operator` with slug, business_name, phone, email. Available at runtime via `Application.get_env(:haul, :operator)`.

## Multi-tenancy

Job uses schema-per-tenant (`:context` strategy). Workers will need the tenant string to load job data. Must pass tenant in Oban job args.

## Test Infrastructure

- **DataCase** (`test/support/data_case.ex`): SQL Sandbox setup, used for DB tests.
- **Mailer tests** (`test/haul/mailer_test.exs`): `import Swoosh.TestAssertions`, `assert_email_sent`.
- **SMS tests** (`test/haul/sms_test.exs`): `assert_received {:sms_sent, message}`.
- **Job tests** (`test/haul/operations/job_test.exs`): Creates company + tenant schema in setup, cleans up in on_exit. `async: false`.

## Config Structure

| Environment | Mailer Adapter | SMS Adapter | Oban (needed) |
|-------------|---------------|-------------|---------------|
| dev | Swoosh.Adapters.Local | Haul.SMS.Sandbox | Postgres queue |
| test | Swoosh.Adapters.Test | Haul.SMS.Sandbox | Oban.Testing inline mode |
| prod | Postmark/Resend | Twilio | Postgres queue |

## Key Constraints

1. Oban needs Postgres — repo must start before Oban in supervision tree.
2. In test, use `Oban.Testing` to run jobs inline or assert enqueued.
3. Workers receive job args as string-keyed maps — must serialize job_id and tenant.
4. SMS Sandbox sends to calling process — in Oban worker context, that's the worker process, so tests need `Oban.Testing.perform_job/3` to run synchronously.
5. Swoosh Test adapter stores emails in a mailbox — `assert_email_sent` works regardless of process.
