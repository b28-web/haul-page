# T-007-03 Design: Notifier Oban Workers

## Decision: Plain Oban Workers (not AshOban)

### Options Considered

**Option A: AshOban triggers on Job resource**
- AshOban can define triggers in the resource DSL that auto-enqueue workers on action completion.
- Pros: Declarative, tightly coupled to Ash lifecycle.
- Cons: AshOban triggers are designed for scheduled/recurring work, not one-shot notifications. The trigger DSL is oriented around polling and scheduling, not post-action hooks. Would add complexity to the Job resource for a simple "enqueue after create" pattern. Version 0.7.x API is still evolving.

**Option B: Ash change module on `:create_from_online_booking`**
- Add a custom `Ash.Resource.Change` that enqueues Oban jobs in `after_action/4`.
- Pros: Runs in the same transaction, guaranteed to fire only on successful create.
- Cons: Slightly more coupling — change module must know about Oban workers.

**Option C: Enqueue in BookingLive after successful submit**
- After `AshPhoenix.Form.submit` returns `{:ok, job}`, insert Oban jobs.
- Pros: Simple, explicit, easy to test.
- Cons: If other code paths create jobs (API, seeds, admin), they won't trigger notifications. Notification logic leaks into the web layer.

### Decision: Option B — Ash Change module

**Rationale:** The notification is a domain concern, not a UI concern. Using an Ash change on the action ensures notifications fire regardless of how the job is created. The `after_action` callback runs after the record is persisted but within the same logical operation, giving us the job ID and all attributes. This is the idiomatic Ash pattern for side effects.

The change module (`Haul.Operations.Changes.EnqueueNotifications`) will:
1. Run in `after_action/4` (not `change/3`)
2. Insert two Oban jobs: SendBookingEmail and SendBookingSMS
3. Pass `job_id` and `tenant` as args (minimal data, workers load fresh)

### Worker Design

**Two separate workers** (not one combined):
- `Haul.Workers.SendBookingEmail` — queue: `:notifications`, max_attempts: 3
- `Haul.Workers.SendBookingSMS` — queue: `:notifications`, max_attempts: 3

Rationale: Email and SMS are independent delivery channels with different failure modes. One failing shouldn't block the other. Separate workers allow independent retry.

**Args:** `%{"job_id" => uuid, "tenant" => tenant_string}`
- Workers load the Job fresh from DB using the tenant context.
- This avoids serializing all job data into Oban args and ensures workers see the latest state.

### Email Content

Plain-text emails (no HTML templates — ticket says "plain-text"):
1. **Customer confirmation** (only if customer_email present): "We received your booking request" with summary.
2. **Operator alert**: "New booking from {name}" with all details. Sent to operator email from config.

### SMS Content

Short message to operator phone: "New booking from {name} — {phone}. {address}"

### Oban Configuration

- Queue: `:notifications` with limit of 10 concurrent.
- Repo: `Haul.Repo`
- Test: `Oban.Testing` with `testing: :manual` for explicit drain/perform.

### Retry Strategy

Oban default exponential backoff. `max_attempts: 3` on each worker. Failed jobs stay in `oban_jobs` table and are visible in logs / Oban dashboard.

### Error Handling

Workers return `{:ok, _}` on success, `{:error, reason}` on failure. Oban handles retry. If the Job record is not found (deleted between enqueue and execute), return `:ok` (skip silently — nothing to notify about).
