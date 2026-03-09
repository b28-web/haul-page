# T-003-01 Review: Job Resource

## Summary

Created `Haul.Operations.Job` Ash resource with AshStateMachine in the new `Haul.Operations` domain. The resource is tenant-scoped, has all required attributes, and the `:create_from_online_booking` action creates jobs in the `:lead` state. Migration generated and applies correctly. All tests pass.

## Files created

| File | Purpose | Lines |
|------|---------|-------|
| `lib/haul/operations.ex` | Operations domain declaration | 8 |
| `lib/haul/operations/job.ex` | Job resource with state machine | 77 |
| `test/haul/operations/job_test.exs` | Job creation + validation tests | 107 |
| `priv/repo/tenant_migrations/20260309005943_create_operations.exs` | Creates jobs table in tenant schema | 37 |
| `priv/resource_snapshots/repo/tenants/jobs/20260309005944.json` | Ash migration snapshot | auto |

## Files modified

| File | Change |
|------|--------|
| `config/config.exs` | Added `Haul.Operations` to `ash_domains` list |

## Acceptance criteria verification

- [x] `Haul.Operations.Job` Ash resource with AshStateMachine — defined with `extensions: [AshStateMachine]`
- [x] Minimum attributes: customer_name, customer_phone, customer_email, address, item_description, preferred_dates, state — all present, plus `notes` and timestamps
- [x] State machine starts at `:lead` — `initial_states [:lead]`, `default_initial_state :lead`
- [x] `:create_from_online_booking` action creates a Job in `:lead` state — tested and verified
- [x] Migration generated and runs successfully — tenant migration created, applies on schema provisioning
- [x] Resource compiles and action is callable from IEx — confirmed via tests (same Ash.create! API)

## Test coverage

**8 new tests, all passing. 73 total tests, 0 failures.**

| Test | What it verifies |
|------|-----------------|
| creates a job in :lead state | Full happy path, all fields, state = :lead |
| requires customer_name | nil → error |
| requires customer_phone | nil → error |
| requires address | nil → error |
| requires item_description | nil → error |
| customer_email is optional | nil email → success |
| notes is optional | notes field works |
| preferred_dates defaults to empty list | no dates → [] |

**Coverage gaps (acceptable):**
- No tests for state transitions (not implemented per AC)
- No policy/authorization tests (no policies defined per design)
- No read action tests (default :read, nothing custom to test)

## Design decisions

1. **No transitions defined** — AshStateMachine requires a corresponding action for each transition. Since only `:lead` is needed, transitions are deferred to future tickets that add the transition actions. The state machine's valid states are implicit in the `initial_states` declaration.

2. **`preferred_dates` as `{:array, :date}`** — Postgres date array. Customers can pick 1-3 preferred dates. Simple, type-safe, queryable.

3. **Added `notes` field** — Not in AC but trivially useful. Optional string for booking form notes or operator notes.

4. **No policies** — The booking form will be a public action (no auth required). Operator-facing policies come with the operator app.

## Open concerns

- **State transitions** — The `state_machine` block currently has no transitions. Future tickets (T-003-02 quote, etc.) will add transitions and their corresponding update actions. This is by design per AC.
- **No relationship to Company** — Job is tenant-scoped but has no explicit `belongs_to :company` relationship. The tenant context provides isolation. An explicit relationship could be added if cross-tenant reporting is needed later.
- **No indexes** — No query indexes beyond the primary key. When the operator app needs to list/filter jobs, indexes on `state`, `inserted_at`, etc. should be added.

## Cross-ticket notes

- **T-003-02 (quote)** will need to add a relationship from Job → Quote and define the `:send_quote` transition action.
- **T-003-03 (booking form)** will use the `:create_from_online_booking` action from a LiveView form. The action accepts all fields needed by the booking flow.
- **The `Haul.Operations` domain is now established.** Future resources (Quote, QuoteLineItem, Truck) go here.
