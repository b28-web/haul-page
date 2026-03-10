# T-025-02 Design: Shared Test Tenant

## Problem

After T-025-01, each test module provisions its own tenant schema in `setup_all`. 10 files use the identical single-owner-context pattern. Sharing one pre-provisioned tenant across these files eliminates 9 redundant schema provisions.

## Options

### Option A: Application env populated in test_helper.exs

Provision a shared tenant in `test_helper.exs` before ExUnit runs. Store the context map in Application env. Test modules opt in by reading it.

```elixir
# test_helper.exs
shared_ctx = HaulWeb.ConnCase.setup_shared_test_tenant()
Application.put_env(:haul, :shared_test_tenant, shared_ctx)
```

- **Pro:** Simple, idiomatic Elixir. No new dependencies. Single point of setup.
- **Pro:** test_helper.exs runs before any test module, guaranteeing availability.
- **Con:** test_helper.exs currently only starts ExUnit and sets sandbox mode. Adding DB operations requires careful ordering.
- **Verdict:** Best approach.

### Option B: Lazy initialization via a GenServer/Agent

Start a named process that provisions on first access, caches for subsequent calls.

- **Pro:** Lazy — only provisions if a test actually needs it.
- **Pro:** No test_helper.exs changes.
- **Con:** Added complexity (process lifecycle, potential race conditions).
- **Con:** First module to access still pays the cost; subsequent modules save nothing vs Option A.
- **Verdict:** Over-engineered for this use case.

### Option C: Named ETS table

Similar to Option A but with ETS lookup instead of Application env.

- **Pro:** Slightly faster lookup.
- **Con:** ETS table lifecycle management. More code for no meaningful benefit.
- **Verdict:** Unnecessary complexity. Application env is fine for a single map lookup.

### Option D: Shared fixture module with module-level state

A module like `Haul.TestFixtures` that provisions in its own `setup_all` and exposes functions.

- **Pro:** Encapsulated.
- **Con:** `setup_all` is per-module — it only runs when ExUnit loads that specific module as a test. A helper module's `setup_all` doesn't run automatically.
- **Verdict:** Doesn't work without explicit invocation from each test file (defeats the purpose).

## Chosen: Option A — Application env in test_helper.exs

### Architecture

1. **Provision once** in `test_helper.exs` after sandbox mode is set to `:manual`.
2. **Store** in `Application.put_env(:haul, :shared_test_tenant, ctx)`.
3. **Helper function** `shared_test_tenant()` in ConnCase to retrieve and validate.
4. **Opt-in** per file: replace `setup_all` block with call to `shared_test_tenant()`.
5. **Cleanup** via `ExUnit.after_suite/1` callback.

### Shared Tenant Module: `Haul.Test.SharedTenant`

Rather than putting provisioning logic directly in test_helper.exs (which should stay minimal), create a module in `test/support/` that encapsulates:
- Provisioning the shared tenant (company + schema + owner user + token)
- Storing/retrieving from Application env
- Cleanup

This keeps test_helper.exs clean and makes the shared tenant reusable.

### Opt-in Pattern for Test Files

Before (per-module setup_all):
```elixir
setup_all do
  ctx = setup_all_authenticated_context()
  on_exit(fn -> cleanup_persistent_tenants(ctx) end)
  %{ctx: ctx}
end
```

After (shared tenant):
```elixir
setup_all do
  %{ctx: shared_test_tenant()}
end
```

No `on_exit` needed — cleanup happens once at suite end.

### Which Files Opt In

**Opt in (9 files):**
- services_live_test.exs
- gallery_live_test.exs
- endorsements_live_test.exs
- site_config_live_test.exs
- onboarding_live_test.exs
- billing_live_test.exs
- billing_qa_test.exs
- domain_settings_live_test.exs
- domain_qa_test.exs

All use a single owner context with per-test sandbox isolation for data.

**Stay private (3 files):**
- dashboard_live_test.exs — needs 3 role-specific contexts
- tenant_isolation_test.exs — needs 2 independent tenants
- security_test.exs — needs 2 companies with specific RBAC setup

### Cleanup Strategy

1. **Start of run** (test_helper.exs): Clean any stale tenant schemas before provisioning. Guards against crashed prior runs.
2. **End of run** (`ExUnit.after_suite/1`): Drop the shared tenant schema and company record.

This double-cleanup approach is already proven by T-025-01's pattern.

### What Rejected and Why

- **Option B (GenServer):** Unnecessary process management for a simple cached value.
- **Option C (ETS):** Same as Application env but harder to debug and maintain.
- **Option D (fixture module):** ExUnit doesn't auto-run `setup_all` for non-test modules.
- **Making dashboard share:** Dashboard tests verify role-based behavior. Sharing one of the 3 contexts saves only 1 provision (~0.15s). Not worth the coupling.
- **Making isolation/security share:** These tests verify data boundaries. Sharing would introduce subtle dependencies that could mask bugs.
