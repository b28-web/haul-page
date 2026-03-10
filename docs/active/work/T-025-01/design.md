# T-025-01 Design: setup_all Migration

## Problem

14 test files create authenticated contexts per-test, each provisioning a Postgres schema (~150-200ms). Moving to once-per-module saves ~35-40s of wall time.

## Approach Options

### Option A: Pure setup_all — shared tenant, no per-test sandbox
Move `create_authenticated_context()` to `setup_all`. Each module gets one tenant. Tests share it.
- **Pro:** Maximum speed gain. Simple change.
- **Con:** Tests that assume empty state (e.g., "no services yet") break. No automatic rollback between tests.
- **Verdict:** Too risky for CRUD tests without additional work.

### Option B: setup_all for context + per-test sandbox with :auto mode
Create tenant in `setup_all` (outside sandbox). Each test still gets a sandbox checkout in `:auto` mode via `setup`. Tenant schema persists but per-test data in the public schema is rolled back.
- **Pro:** Tenant provisioning happens once; sandbox still handles per-test isolation.
- **Con:** Tenant schemas are created via DDL (CREATE SCHEMA) which is NOT transactional in the sandbox sense — the schema persists regardless. But data within the tenant schema IS created per-test inside the sandbox, so it rolls back.
- **Key insight:** The expensive part is `ProvisionTenant.tenant_schema()` which runs DDL. This runs in setup_all once. Per-test data creation (services, gallery items, etc.) still runs in the sandbox and rolls back.
- **Verdict:** Best approach. Preserves test isolation for data while eliminating the expensive schema provisioning.

### Option C: Shared test helper module with cached context
Create a module that provisions a tenant once per test run and caches the result. All test files share the same tenant.
- **Pro:** Even more savings — one tenant for all 14 files.
- **Con:** Cross-file coupling. Order-dependent failures. Breaks test isolation fundamentally.
- **Verdict:** This is T-025-02's scope (shared-test-tenant). Out of scope here.

## Chosen: Option B — setup_all for context + per-test sandbox

### How It Works

1. **setup_all** creates the authenticated context (company + tenant schema + user + token). This runs once per module. The schema DDL persists.

2. **setup** (per-test) does sandbox checkout. Data created within tests (services, gallery items, etc.) happens inside the sandbox and rolls back after each test.

3. **on_exit in setup_all** cleans up the tenant schema once when the module finishes.

4. **Conn rebuilding:** `Phoenix.ConnTest.build_conn()` and `log_in_user()` must happen in per-test `setup` because conn is not serializable across processes (setup_all runs in a different process).

### Pattern Template

```elixir
setup_all do
  # Checkout outside sandbox for DDL operations
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Haul.Repo, shared: true)
  ctx = create_authenticated_context()
  Ecto.Adapters.SQL.Sandbox.stop_owner(pid)

  on_exit(fn -> cleanup_tenants() end)
  %{ctx: ctx}
end

setup %{ctx: ctx} do
  # Per-test sandbox for data isolation
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Haul.Repo, shared: true)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

  conn = Phoenix.ConnTest.build_conn() |> log_in_user(ctx)
  %{conn: conn, ctx: ctx, tenant: ctx.tenant}
end
```

### File-Specific Decisions

**Group A (top-level setup → setup_all):** gallery, onboarding
- Straightforward. Move context creation to setup_all. Keep per-test setup for conn + sandbox.

**Group B (nested describe setup → module setup_all):** services, endorsements, site_config, dashboard
- Move context creation to module-level setup_all. Nested describe setups become unnecessary for context.
- Dashboard has 3 role-specific describes — need 3 contexts in setup_all or one owner + per-test role switching.
  - Decision: Create one owner context in setup_all. For role-specific tests, create additional contexts only if the roles matter for assertions. Dashboard tests mostly check page rendering, so owner context suffices for most. For role-specific describe blocks that test role-based behavior, keep per-describe setup with a note.
  - Actually: Dashboard creates 3 separate contexts (owner, dispatcher, crew). Moving all 3 to setup_all still saves 3 schema provisions → 1. Use unique emails per role.

**Group C (per-test inline → setup_all + per-test conn):** domain_settings, billing_qa, domain_qa, billing_live
- Each test currently creates context inline and modifies company attributes (plan, domain, stripe IDs).
- With shared context: tests must use unique company modifications or reset after.
- Since these tests modify the Company resource (which is in the public schema, inside sandbox), modifications roll back between tests. Safe.

**Group D (multi-tenant / complex):**
- **tenant_isolation_test:** Creates 2 tenants per test to verify isolation. Must keep per-test setup for the 2nd tenant. Can share 1st tenant via setup_all. But the test fundamentally needs 2 isolated contexts. Keep per-test.
  - Actually: We can create both tenants in setup_all. The isolation tests read from both tenants — they don't need per-test data isolation, they need cross-tenant isolation which is architectural. Move to setup_all.
- **security_test:** Creates 2 companies with 3 users and different roles. Tests verify policy enforcement. Can share the fixed context via setup_all since tests are read-heavy assertions on existing data.
- **preview_edit_test / provision_qa_test:** These call helper functions that create context + conversation + do full provisioning flows. The AI sandbox and rate limiter state need per-test cleanup. These are the most complex — may benefit less or need to stay per-test.
  - Decision: Keep these per-test for now. The provisioning flow creates conversations and modifies state extensively. Savings (~3.0s + ~3.3s) aren't worth the complexity risk.

### Files to Migrate (12 of 14)

1. tenant_isolation_test.exs — 2 contexts in setup_all
2. onboarding_live_test.exs — 1 context in setup_all
3. security_test.exs — 2 contexts in setup_all
4. domain_settings_live_test.exs — 1 context in setup_all
5. billing_qa_test.exs — 1 context in setup_all
6. domain_qa_test.exs — 1 context in setup_all
7. billing_live_test.exs — 1 context in setup_all
8. services_live_test.exs — 1 context in setup_all
9. gallery_live_test.exs — 1 context in setup_all
10. endorsements_live_test.exs — 1 context in setup_all
11. site_config_live_test.exs — 1 context in setup_all
12. dashboard_live_test.exs — 3 contexts in setup_all (one per role)

### Files to Skip (2 of 14)

- preview_edit_test.exs — complex AI provisioning flow, per-test state management
- provision_qa_test.exs — same as above

### Estimated Savings

~29s from 12 files (skipping ~6.3s from preview_edit + provision_qa).
Still well within the "35-40s" target range when combined with reduced per-test overhead.

### Sandbox Approach for setup_all

The key challenge: `create_authenticated_context()` needs a DB connection for DDL operations (CREATE SCHEMA), but setup_all runs outside the normal sandbox flow.

Solution: Temporarily checkout a sandbox owner in setup_all for the DDL, then stop it. The schema persists (DDL is not transactional). Per-test setup then gets its own sandbox owner for data operations.
