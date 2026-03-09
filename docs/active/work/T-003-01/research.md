# T-003-01 Research: Job Resource

## Ticket scope

Create `Haul.Operations.Job` Ash resource with AshStateMachine. Minimum attributes: customer_name, customer_phone, customer_email, address, item_description, preferred_dates, state. Action `:create_from_online_booking` creates a Job in `:lead` state. Migration generated and runnable.

## Dependency: T-004-01 (complete)

T-004-01 established the Ash resource pattern used throughout the project:

- **Domain pattern:** `Haul.Accounts` domain at `lib/haul/accounts.ex` — simple `use Ash.Domain` + `resources do ... end`
- **Resource pattern:** `Haul.Accounts.Company` at `lib/haul/accounts/company.ex` — `use Ash.Resource, domain: ..., data_layer: AshPostgres.DataLayer`
- **Multi-tenancy:** Schema-per-tenant via `AshPostgres.MultiTenancy` with `:context` strategy. Company is public schema; User/Token are tenant-scoped.
- **Migrations:** Generated via `mix ash_postgres.generate_migrations`, tenant migrations go to `priv/repo/tenant_migrations/`.
- **Test pattern:** `use Haul.DataCase, async: false`, setup creates a company + provisions tenant schema, teardown drops tenant schemas.

## Existing infrastructure

### Database layer
- `Haul.Repo` — AshPostgres.Repo, extensions: uuid-ossp, citext, ash-functions. Min PG 16.
- Public schema: `companies` table
- Tenant schemas (`tenant_{slug}`): `users`, `tokens` tables
- Migration pipeline fully working (both public and tenant migrations)

### Ash dependencies (all installed)
- `ash 3.19` — core
- `ash_postgres 2.7` — data layer
- `ash_state_machine 0.2.12` — **needed for Job states**
- `ash_phoenix 2.3` — form helpers (useful for booking form later)
- `ash_archival 2.0` — soft deletes (potential future use for Job)
- `ash_paper_trail 0.5.7` — audit logging (potential future use)

### Configuration
- `config :haul, ash_domains: [Haul.Accounts]` — needs `Haul.Operations` added
- No Operations domain exists yet — this ticket creates it

## AshStateMachine 0.2.x API

From the ash_state_machine hex docs and source:

```elixir
use Ash.Resource,
  extensions: [AshStateMachine]

state_machine do
  initial_states [:lead]
  default_initial_state :lead

  transitions do
    transition :accept, from: :lead, to: :quoted
    transition :schedule, from: :quoted, to: :scheduled
    # ...
  end
end
```

- Adds a `:state` attribute automatically (atom type, stored as string in PG)
- Transitions are enforced on update actions tagged with `change transition_state(:target_state)`
- The `initial_states` list defines valid states for create actions
- `default_initial_state` sets the state on create if not explicitly provided

## Job states (from spec)

The spec mentions the following lifecycle: lead → quoted → scheduled → completed → invoiced. Also mentions `:cancelled` as a terminal state. For T-003-01, only `:lead` needs to work — other states are defined but transitions not implemented beyond `:lead`.

Full state list for definition:
- `:lead` — initial, from online booking
- `:quoted` — quote sent to customer
- `:scheduled` — job date confirmed
- `:en_route` — crew dispatched (implied by spec's truck tracking)
- `:in_progress` — crew on site
- `:completed` — work done
- `:invoiced` — invoice sent
- `:paid` — payment received
- `:cancelled` — cancelled at any point

## Job attributes (from acceptance criteria + spec)

Required for T-003-01:
- `customer_name` — string, required
- `customer_phone` — string, required
- `customer_email` — string, optional (some customers may not provide)
- `address` — string, required
- `item_description` — text, required
- `preferred_dates` — needs a type decision (see Design)
- `state` — managed by AshStateMachine

## Multi-tenancy decision

Job MUST be tenant-scoped. Each operator (company) has their own jobs. This follows the same pattern as User — `multitenancy strategy: :context` in the postgres block, migration in `priv/repo/tenant_migrations/`.

## Test infrastructure

- `Haul.DataCase` provides sandbox setup
- Company creation provisions a tenant schema automatically
- Tests need `async: false` for schema creation/cleanup
- Pattern: create company → use `ProvisionTenant.tenant_schema(slug)` as tenant → create resources with `tenant:` option

## Files that will be created or modified

New files:
- `lib/haul/operations.ex` — Operations domain
- `lib/haul/operations/job.ex` — Job resource
- `test/haul/operations/job_test.exs` — Job tests
- `priv/repo/tenant_migrations/YYYYMMDD_create_operations.exs` — generated migration

Modified files:
- `config/config.exs` — add `Haul.Operations` to ash_domains list
