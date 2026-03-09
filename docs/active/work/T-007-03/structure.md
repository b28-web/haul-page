# T-007-03 Structure: Notifier Oban Workers

## New Files

### `lib/haul/workers/send_booking_email.ex`
- `Haul.Workers.SendBookingEmail`
- `use Oban.Worker, queue: :notifications, max_attempts: 3`
- `perform/1`: loads Job by id with tenant, builds + delivers email via `Haul.Mailer`
- Sends customer confirmation (if email present) + operator alert

### `lib/haul/workers/send_booking_sms.ex`
- `Haul.Workers.SendBookingSMS`
- `use Oban.Worker, queue: :notifications, max_attempts: 3`
- `perform/1`: loads Job by id with tenant, sends SMS via `Haul.SMS.send_sms/3`
- Sends operator SMS with customer name + phone + address

### `lib/haul/operations/changes/enqueue_notifications.ex`
- `Haul.Operations.Changes.EnqueueNotifications`
- `use Ash.Resource.Change`
- `after_action/4`: inserts SendBookingEmail and SendBookingSMS Oban jobs
- Args: `%{"job_id" => job.id, "tenant" => changeset.tenant}`

### `test/haul/workers/send_booking_email_test.exs`
- Tests email worker: loads job, sends customer + operator emails
- Tests skip when job not found
- Tests skip when no customer email (operator alert still sent)

### `test/haul/workers/send_booking_sms_test.exs`
- Tests SMS worker: loads job, sends operator SMS
- Tests skip when job not found

### `test/haul/operations/changes/enqueue_notifications_test.exs`
- Tests that creating a job via `:create_from_online_booking` enqueues both workers

## Modified Files

### `config/config.exs`
- Add Oban config: `config :haul, Oban, repo: Haul.Repo, queues: [notifications: 10]`

### `config/test.exs`
- Add: `config :haul, Oban, testing: :manual`

### `lib/haul/application.ex`
- Add `{Oban, Application.fetch_env!(:haul, Oban)}` to children, after Repo and before Endpoint

### `lib/haul/operations/job.ex`
- Add `change Haul.Operations.Changes.EnqueueNotifications` to `:create_from_online_booking` action

## Module Dependencies

```
BookingLive → AshPhoenix.Form.submit → Job :create_from_online_booking
  → EnqueueNotifications (after_action)
    → Oban.insert(SendBookingEmail)
    → Oban.insert(SendBookingSMS)

SendBookingEmail.perform → Ash.get(Job, id, tenant: t) → Haul.Mailer.deliver
SendBookingSMS.perform → Ash.get(Job, id, tenant: t) → Haul.SMS.send_sms
```

## Public Interfaces

- `SendBookingEmail.new(%{"job_id" => id, "tenant" => t})` — creates Oban changeset
- `SendBookingSMS.new(%{"job_id" => id, "tenant" => t})` — creates Oban changeset
- Both workers are internal; no public API beyond Oban's standard interface
