# T-034-02 Structure: setup_all Quick Wins

## Files Modified

### 1. `test/haul_web/controllers/page_controller_test.exs`
**Change:** Replace `setup do` with `setup_all do` for tenant provisioning + content seeding.

Before:
- `setup do` — creates company, provisions tenant, seeds content, drops tenants on exit
- Each test receives `conn`, `host`, `tenant`

After:
- `setup_all do` — creates company, provisions tenant, seeds content, cleans up on exit
- `setup %{...} do` — builds fresh conn per test
- Returns `company`, `tenant`, `host` from setup_all
- `conn` from per-test setup

### 2. `test/haul_web/live/app/onboarding_live_test.exs`
**Change:** Move top-level `setup do` to `setup_all do`. Keep "public pages" describe's nested setup unchanged.

Before:
- Top `setup do` — `create_authenticated_context()`, provision tenant, seed content, cleanup
- Nested "public pages" `setup do` — `Haul.Onboarding.run/1`, sets operator config

After:
- Top `setup_all do` — same operations, run once
- Per-test `setup` — builds conn, logs in user
- "public pages" describe — unchanged (its setup creates its own tenant)

### 3. `test/haul_web/live/admin/accounts_live_test.exs`
**Change:** Move admin + company creation to `setup_all do` for "accounts list" describe.

Before:
- `setup [:setup_admin, :create_companies]` — runs both per test
- Inline `setup_admin/1` and `create_companies/1` defp functions

After:
- Module-level `setup_all do` — creates admin + 2 companies once
- Per-test `setup` — builds conn
- Remove `setup_admin/1` and `create_companies/1` defp functions (inline into setup_all)
- Security describe stays unchanged — no dependency on shared state

### 4. `docs/knowledge/test-architecture.md`
**Change:** Expand the setup_all section with a concrete pattern example.

Add after line 134:
- Pattern showing setup_all with sandbox checkout, :auto mode, factory usage, on_exit cleanup
- Note about reverting to :manual mode for ConnCase compatibility

## Files NOT Modified

- `test/haul_web/live/admin/impersonation_test.exs` — already `async: true`, skip
- `test/support/conn_case.ex` — no changes needed (setup_all handles sandbox manually)
- `test/support/data_case.ex` — no changes needed
- `test/support/factories.ex` — no changes needed (already has the right building blocks)
- `test/support/shared_tenant.ex` — not used (different mechanism)

## Module Boundaries

No new modules. No public interface changes. All modifications are internal to test file setup blocks.

## Ordering

1. page_controller_test.exs first — simplest conversion (all read-only, no nested setup blocks)
2. onboarding_live_test.exs second — partial conversion with nested setup to preserve
3. accounts_live_test.exs third — requires restructuring named setup functions
4. test-architecture.md last — document the pattern after verifying it works
