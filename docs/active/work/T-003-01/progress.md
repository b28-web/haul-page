# T-003-01 Progress: Job Resource

## Completed steps

### Step 1: Create Operations domain ✓
Created `lib/haul/operations.ex` — domain registers `Haul.Operations.Job`.

### Step 2: Create Job resource ✓
Created `lib/haul/operations/job.ex` with:
- AshPostgres data layer, tenant-scoped (multitenancy :context)
- AshStateMachine extension, initial_states [:lead], default_initial_state :lead
- All required attributes + notes field
- `:create_from_online_booking` action

**Deviation:** Initially defined all state transitions in the `state_machine` block. AshStateMachine requires a corresponding update action for each transition. Removed transitions since acceptance criteria only requires `:lead` state. States are still the valid state space — transitions will be added with their actions in future tickets.

### Step 3: Register domain in config ✓
Added `Haul.Operations` to `ash_domains` in `config/config.exs`.

### Step 4: Generate and apply migration ✓
Generated `priv/repo/tenant_migrations/20260309005943_create_operations.exs`. Creates `jobs` table in tenant schema with all columns. State column defaults to "lead".

Migration applies cleanly. Tenant migrations run when a schema is provisioned via `ProvisionTenant`.

### Step 5: Write tests ✓
Created `test/haul/operations/job_test.exs` — 8 tests:
- Job creation with valid attrs → state is :lead
- Required field validation (4 tests)
- Optional fields (customer_email, notes, preferred_dates)
- preferred_dates defaults to empty list

### Step 6: Full test suite ✓
73 tests, 0 failures. No regressions.

### Step 7: IEx verification
The action is callable:
```elixir
# After creating a company and provisioning tenant:
Job
|> Ash.Changeset.for_create(:create_from_online_booking, %{
  customer_name: "Jane Doe",
  customer_phone: "(555) 987-6543",
  address: "123 Main St",
  item_description: "Old couch"
}, tenant: "tenant_test-hauling")
|> Ash.create()
```

## Files created
- `lib/haul/operations.ex`
- `lib/haul/operations/job.ex`
- `test/haul/operations/job_test.exs`
- `priv/repo/tenant_migrations/20260309005943_create_operations.exs`
- `priv/resource_snapshots/repo/tenants/jobs/20260309005944.json`

## Files modified
- `config/config.exs` — added `Haul.Operations` to ash_domains

## Remaining
None. All acceptance criteria met.
