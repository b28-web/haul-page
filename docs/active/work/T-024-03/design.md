# T-024-03 Design: Fix Slow Tests

## Problem

173s test suite. Three root causes: redundant per-test tenant provisioning (51%), extraction debounce sleeps (21%), bcrypt cost (4%).

## Approach Selection

### Option A: `setup_all` for read-only test files + configurable debounce + bcrypt reduction

Move security_test, tenant_isolation_test, and dashboard_live_test to `setup_all` (they're read-only). For the ~12 admin LiveView files that mutate state, keep per-test setup but reduce cost via bcrypt rounds reduction. Make extraction debounce configurable for chat test speedup.

**Pros:** Safe, conservative, well-understood patterns. Each change is independent.
**Cons:** Only saves ~8s from `setup_all` on read-only files. The 12 mutating files still pay full per-test setup cost.
**Estimated savings:** 8s (setup_all) + 15-20s (debounce) + 6s (bcrypt) = ~30-34s → ~140s

### Option B: Shared tenant fixture module + per-test sandbox isolation

Create a `Haul.TestFixtures` module that provisions a shared tenant in `setup_all`, then uses Ecto sandbox allowances so each test gets isolated DB state within that tenant. The schema exists once; data isolation comes from sandbox rollback.

**Pros:** Eliminates schema DDL cost across all files. Massive savings.
**Cons:** Ecto sandbox doesn't isolate schema-level DDL. `CREATE SCHEMA` is DDL — it's not rolled back by sandbox. This approach fundamentally doesn't work for multi-tenant with schema-per-tenant. **Rejected.**

### Option C: `setup_all` everywhere + test-specific data prefixes

Move all admin tests to `setup_all`. Tests that assert "empty state" get refactored to assert on specific items rather than emptiness. Tests that mutate company state use `Ash.update` at start of test to set their needed state.

**Pros:** Maximizes setup savings across all files.
**Cons:** Fragile — tests become coupled to shared state. Order-dependent failures. Significantly harder to debug.
**Rejected — too fragile for the savings.**

### Option D (Chosen): Targeted `setup_all` + bcrypt reduction + configurable debounce

Combine the safe parts:

1. **`setup_all` for 3 read-only files** — security_test, tenant_isolation_test, dashboard_live_test (~8.5s savings)
2. **Bcrypt rounds = 1 in test** — `config :bcrypt_elixir, log_rounds: 1` in test.exs (~6s savings across all files)
3. **Configurable extraction debounce** — `Application.get_env(:haul, :extraction_debounce_ms, 800)` in chat_live.ex, set to 50ms in test.exs. Reduce chat test sleeps from 1500ms to 200ms. (~15-20s savings)
4. **Async conversion** for 4 trivially async files (<1s but free)
5. **Reduce rate-limit loop counts** in tests where full 50 iterations aren't needed (~2s)

**Total estimated savings: 32-37s → target runtime ~136-141s**

This falls short of the 60s target. To close the gap further:

6. **Parallel `setup` optimization** — refactor `create_authenticated_context/1` to minimize DB round-trips (combine company+user creation, skip sign-in where token isn't needed). Potential: reduce from 150-200ms to ~80-100ms per call. With ~200 calls across the suite, saves ~15-25s.

**Revised estimate: 47-62s → target achievable on the lower end.**

If we don't hit 60s, we document what's left per the ticket's acceptance criteria.

## Decision: Option D with item 6

### Detailed Design

#### 1. Bcrypt rounds in test (global, 6s savings)

Add to `config/test.exs`:
```elixir
config :bcrypt_elixir, log_rounds: 1
```

This is the standard Phoenix convention. It affects all `register_with_password` and `sign_in_with_password` calls.

#### 2. Configurable extraction debounce (15-20s savings)

In `chat_live.ex`, change:
```elixir
@extraction_debounce_ms 800
```
to:
```elixir
@extraction_debounce_ms Application.compile_env(:haul, :extraction_debounce_ms, 800)
```

In `config/test.exs`:
```elixir
config :haul, extraction_debounce_ms: 50
```

Then reduce `Process.sleep(1500)` in chat tests to `Process.sleep(200)` (50ms debounce + 100ms extraction + 50ms buffer).

#### 3. `setup_all` for read-only test files (8.5s savings)

**security_test.exs:** Move setup block to `setup_all`. Keep `on_exit` cleanup — ExUnit runs `on_exit` registered in `setup_all` after all tests complete. Must also set up Ecto sandbox in `setup` (per-test) with `shared: true` mode since `setup_all` runs in a separate process.

Pattern:
```elixir
setup_all do
  # Provision tenants and users once
  ...
  on_exit(fn -> cleanup schemas end)
  %{...shared data...}
end

setup %{...} = context do
  # Per-test sandbox
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Haul.Repo, shared: true)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  context
end
```

Wait — there's a subtlety. `setup_all` runs before `setup`. But the sandbox in `setup_all` is owned by the `setup_all` process which exits. The tenant schemas created via DDL persist outside the sandbox, so they survive. But Ecto reads within tests need a sandbox checkout.

Actually, the schema DDL (CREATE SCHEMA, CREATE TABLE) happens outside the sandbox — it's raw SQL via `Ecto.Adapters.SQL.query!`. The data inserted via Ash (companies, users) goes through the sandbox. So we need the sandbox to be shared from `setup_all` through all tests.

Simpler approach: Use `Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)` for these specific test modules, and don't rely on sandbox rollback (since we're cleaning up schemas manually via `on_exit`).

Actually, the cleanest approach for these read-only files: provision in `setup_all` outside the sandbox, clean up schemas in `on_exit`. Each test gets its own sandbox checkout for any reads. Since tests only read, sandbox rollback is irrelevant.

#### 4. Async conversion (< 1s)

Convert these to `async: true`:
- `qr_controller_test.exs`
- `health_controller_test.exs`
- `rate_limiter_test.exs`
- `chat_test.exs`

#### 5. Rate-limit loop reduction (~2s)

Chat rate-limit tests send 50 messages. The rate limit is enforced at 50. We could lower the limit in test config to 10, reducing loop iterations from 50 to 10. Add `config :haul, :max_chat_messages, 10` in test.exs and use it in chat_live.ex.

#### 6. Streamline `create_authenticated_context/1` (~15-25s)

The current flow does 5 DB operations. We can optimize:
- Skip `sign_in_with_password` (bcrypt verify + token gen) when the test doesn't need a token — create a helper that returns just `{company, tenant, user}` without auth
- For LiveView tests that need `log_in_user`, generate a token directly via `AshAuthentication.Strategy.Password` instead of the full sign-in flow

This requires careful analysis of which tests actually use the token vs just the conn session.

## Risks

1. `setup_all` + `on_exit` schema cleanup — if test crashes, schema may not be cleaned up. Mitigated by existing `cleanup_tenants()` pattern that drops all `tenant_*` schemas.
2. Reducing bcrypt rounds in test — no risk, standard practice.
3. Configurable debounce — tiny risk if `Application.compile_env` is cached at compile time. Test with `mix test` after config change.
4. Rate-limit config — if chat_live.ex reads `@max_messages` at compile time, need `compile_env`.

## Non-goals (per ticket)

- Don't delete tests
- Don't stub out real behavior
- Don't parallelize at OS level
