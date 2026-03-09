# T-007-03 Progress: Notifier Oban Workers

## Completed

### Step 1: Oban Configuration
- Added Oban config to `config/config.exs` (repo: Haul.Repo, queues: [notifications: 10])
- Added `testing: :manual` to `config/test.exs`
- Added `{Oban, ...}` to application supervisor after Repo
- Generated and ran Oban migration (version 12)
- All existing tests still pass

### Step 2: Email Worker
- Created `Haul.Workers.SendBookingEmail` with `use Oban.Worker, queue: :notifications, max_attempts: 3`
- Sends operator alert (always) and customer confirmation (when email present)
- Graceful skip when job not found
- 3 tests passing

### Step 3: SMS Worker
- Created `Haul.Workers.SendBookingSMS` with `use Oban.Worker, queue: :notifications, max_attempts: 3`
- Sends operator SMS with customer name, phone, and address
- Graceful skip when job not found
- 2 tests passing

### Step 4: Ash Change + Integration
- Created `Haul.Operations.Changes.EnqueueNotifications` as Ash Change module
- Added `change` to `:create_from_online_booking` action in Job resource
- Integration test verifies both workers enqueued on job creation
- 1 test passing

## Result

All 6 new tests pass. Full suite: 145 tests, 0 failures. No deviations from plan.
