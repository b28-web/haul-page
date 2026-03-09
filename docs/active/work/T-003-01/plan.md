# T-003-01 Plan: Job Resource

## Step 1: Create Operations domain

Create `lib/haul/operations.ex` with `Haul.Operations` domain module. Register `Haul.Operations.Job` as a resource.

Verify: module compiles (`mix compile`).

## Step 2: Create Job resource

Create `lib/haul/operations/job.ex` with:
- AshPostgres data layer (table "jobs", multitenancy :context)
- AshStateMachine extension with full state list, initial_states [:lead]
- All attributes per design
- `:create_from_online_booking` action
- Default `:read` action

Verify: module compiles.

## Step 3: Register domain in config

Add `Haul.Operations` to `ash_domains` list in `config/config.exs`.

Verify: `mix compile` succeeds with no warnings.

## Step 4: Generate and apply migration

Run `mix ash_postgres.generate_migrations --name create_operations`.
Review generated migration for correctness.
Run `mix ash_postgres.migrate` (runs both public and tenant migrations).

Verify: migration applies cleanly.

## Step 5: Write tests

Create `test/haul/operations/job_test.exs` with tests for:
- Successful job creation with all required fields
- State defaults to :lead
- Required field validation (customer_name, customer_phone, address, item_description)
- Optional fields work (customer_email, notes, preferred_dates)
- preferred_dates stores date list correctly

Verify: `mix test test/haul/operations/job_test.exs` passes.

## Step 6: Run full test suite

Run `mix test` to ensure nothing is broken.

Verify: all tests pass (existing + new).

## Step 7: IEx smoke test

Verify the action is callable from IEx per acceptance criteria. Document the command in progress.md.

## Testing strategy

- **Unit tests:** Job resource creation, field validation, state machine initial state
- **No integration tests needed:** No routes, no LiveView, no cross-resource relationships yet
- **No security tests needed:** No policies defined (deferred per design)
- All tests use `async: false` with tenant schema setup/cleanup pattern from CompanyTest
