# T-034-02 Design: setup_all Quick Wins

## Decision Summary

Convert 3 files to setup_all. Skip impersonation_test.exs (already async:true, net negative).

## Options Evaluated

### Option A: Convert All 4 Remaining Files
- Convert onboarding_live, page_controller, impersonation, accounts_live
- **Rejected:** impersonation_test.exs is `async: true`. Converting to setup_all requires `async: false` (DDL must commit). Losing async parallelism likely costs more than the ~400ms saved per test on setup. The test has 16 tests — at ~100ms each in parallel vs ~400ms saved once, the math doesn't favor conversion.

### Option B: Convert 3 Files, Skip Impersonation (CHOSEN)
- Convert: page_controller_test.exs, onboarding_live_test.exs, accounts_live_test.exs
- Skip: impersonation_test.exs (async:true — already fast)
- Estimated savings: ~10s
- Lower risk, clear wins

### Option C: Only Convert page_controller_test.exs (Safest)
- **Rejected:** Too conservative. The onboarding and accounts tests are also good candidates with manageable complexity.

## Conversion Pattern

Each converted file follows this pattern:

```elixir
setup_all do
  # 1. Manual sandbox checkout in :auto mode for DDL
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

  # 2. Create shared state (company, tenant, user, token, seed content)
  ctx = Haul.Test.Factories.build_authenticated_context()
  # ... any additional setup (seeding, admin creation, etc.)

  # 3. Cleanup on exit
  on_exit(fn ->
    Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)
    Haul.Test.Factories.cleanup_all_tenants()
  end)

  # 4. Return shared state (available to all tests and setup blocks)
  %{tenant: ctx.tenant, user: ctx.user, token: ctx.token, company: ctx.company}
end

# Per-test setup: only things that can't be shared (conn)
setup %{token: token, tenant: tenant} do
  %{conn: Phoenix.ConnTest.build_conn()}
end
```

### ConnCase sandbox conflict
The ConnCase `setup` block calls `Haul.DataCase.setup_sandbox(tags)` which runs `Sandbox.start_owner!`. This conflicts with our manual sandbox management in setup_all.

**Solution:** Override by adding `@tag :skip_sandbox` and checking it in setup, OR simply let it run — `start_owner!` in shared mode should coexist with `:auto` mode since `:auto` was set before. Actually, the simpler approach: we'll need to handle this. The ConnCase setup runs *after* setup_all, and calling `start_owner!` after we've set `:auto` mode will conflict.

**Best approach:** Don't fight ConnCase's setup. Instead, make the setup_all do its DDL work, then let ConnCase's normal sandbox setup manage per-test connections. The key insight: setup_all runs once, commits DDL via `:auto`, then the sandbox reverts to `:manual` mode (which ConnCase expects). We need to explicitly set mode back to `:manual` at the end of setup_all.

Revised pattern:
```elixir
setup_all do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

  ctx = Haul.Test.Factories.build_authenticated_context()
  Haul.Content.Seeder.seed!(ctx.tenant)  # if needed

  on_exit(fn ->
    Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)
    Haul.Test.Factories.cleanup_all_tenants()
  end)

  # Revert to manual so ConnCase setup_sandbox works normally
  Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)

  %{company: ctx.company, tenant: ctx.tenant, user: ctx.user, token: ctx.token}
end
```

Since `:auto` mode committed the DDL (CREATE SCHEMA, tables), the tenant schema persists even after sandbox reverts to `:manual`. Per-test sandboxed connections can read from it.

Wait — but sandboxed connections wrap each test in a transaction. Reads of data in the public schema (companies table) should work, but reads of tenant-schema data require the sandbox connection to access the tenant schema. Since DDL was committed, the schema exists on disk, and SELECT within the sandbox transaction should see it.

**Actually:** There's a subtlety. Data inserted in `:auto` mode is committed. When the sandbox wraps the next test in a transaction, it can read committed data. So companies, users, and seeded content are all visible. This should work.

## Per-File Design

### page_controller_test.exs
- All 8 tests are read-only GET requests asserting HTML content
- setup_all: create company (with operator slug), provision tenant, seed content
- setup: build conn, set host
- No mutation concerns

### onboarding_live_test.exs
- Main tests (8 in describes auth, navigation, steps 1-5): mostly read-only LiveView navigation
- Step 1 "saves info" test submits a form — writes to SiteConfig. But the form submit just advances to step 2, and other tests don't assert on the original values.
- Step 6 "go live" test sets `onboarding_complete = true` on the company. Subsequent tests would see this. But no other test asserts `onboarding_complete == false`.
- "public pages" describe (6 tests): keeps its own nested `setup` — creates a separate tenant via `Haul.Onboarding.run/1`. Cannot share the main setup_all tenant. This block stays as-is.
- **Decision:** Convert the top-level setup to setup_all. Keep "public pages" setup block unchanged.

### accounts_live_test.exs
- "accounts list" describe (7 tests): uses `[:setup_admin, :create_companies]` — all read-only
- "accounts list security" describe (3 tests): no shared setup, creates own context inline
- setup_all: create admin + 2 companies
- setup: build conn
- The security tests don't need setup_all state — they test unauthenticated/invalid access

**Complication:** `setup_admin` and `create_companies` are defp functions called as named setups. With setup_all, we'll inline them or call factory functions directly.

## Documentation Update

The test-architecture.md already has a brief section on setup_all vs setup (lines 129-134). It says "Most tests use setup. Prefer setup unless profiling shows per-test cost is a bottleneck." This is still correct — we'll add a concrete example pattern showing the sandbox checkout + :auto + revert pattern.

## Risks and Mitigations

1. **Shared state mutation** — Step 6 onboarding test mutates company. Mitigated: no other test depends on pre-mutation state.
2. **Sandbox mode conflicts** — setup_all uses :auto, ConnCase setup expects :manual. Mitigated: revert to :manual after setup_all completes.
3. **on_exit cleanup** — Must re-checkout and set :auto in on_exit callback since sandbox state is per-process. The on_exit runs in a separate process.
4. **Reduced savings** — Original ticket estimated ~25-29s. With superadmin_qa deleted and impersonation skipped, actual savings ~10s. Still worthwhile.
