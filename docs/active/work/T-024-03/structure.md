# T-024-03 Structure: Fix Slow Tests

## Files Modified

### Config
- **`config/test.exs`** — Add bcrypt rounds, extraction debounce, max chat messages configs

### Production Code (minimal)
- **`lib/haul_web/live/chat_live.ex`** — Replace hardcoded `@extraction_debounce_ms 800` with `Application.compile_env(:haul, :extraction_debounce_ms, 800)`. Replace hardcoded `@max_messages 50` with `Application.compile_env(:haul, :max_chat_messages, 50)`.

### Test Files — `setup_all` Migration

#### Read-only files (safe — tests never mutate setup data):
- **`test/haul/accounts/security_test.exs`** — Move entire `setup` block to `setup_all`. Add per-test `setup` for sandbox. Adjust `on_exit` to file-level cleanup.
- **`test/haul/tenant_isolation_test.exs`** — Same pattern as security_test.
- **`test/haul_web/live/app/dashboard_live_test.exs`** — Move auth context creation to `setup_all`.

### Test Files — Sleep Reduction

- **`test/haul_web/live/chat_qa_test.exs`** — Reduce `Process.sleep(1500)` → `Process.sleep(200)` (debounce now 50ms in test). Reduce `Process.sleep(500)` → `Process.sleep(150)`.
- **`test/haul_web/live/chat_live_test.exs`** — Same sleep reductions.
- **`test/haul_web/live/chat_qa_test.exs`** — Reduce rate-limit loop from 50 → 10 iterations (config-driven).
- **`test/haul_web/live/chat_live_test.exs`** — Same rate-limit adjustment.

### Test Files — Async Conversion

- **`test/haul_web/controllers/qr_controller_test.exs`** — Change `async: false` to `async: true`
- **`test/haul_web/controllers/health_controller_test.exs`** — Change to `async: true`
- **`test/haul/rate_limiter_test.exs`** — Change to `async: true` (uses isolated ETS, no DB)
- **`test/haul/ai/chat_test.exs`** — Change to `async: true` (no DB, uses ChatSandbox per-process)

## Files NOT Modified

- Admin LiveView tests (services, gallery, endorsements, etc.) — keep per-test setup, benefit from bcrypt speedup only
- preview_edit_test.exs, provision_qa_test.exs — per-test provisioning is inherent to their test logic
- data_case.ex, conn_case.ex — no structural changes needed
- test_helper.exs — no changes needed

## Module Boundaries

No new modules. Changes are config-driven and test-file-local.

## Change Ordering

1. `config/test.exs` — must be first (bcrypt + debounce affect all subsequent test runs)
2. `chat_live.ex` — compile_env for debounce/max_messages (production code, needs clean compile)
3. Async conversions — independent, low risk
4. `setup_all` migrations — independent per file
5. Chat test sleep reductions — depends on step 1+2

## Architecture Notes

### `setup_all` Pattern for Tenant Tests

```elixir
setup_all do
  # Start a sandbox owner for setup_all operations
  Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

  # Provision once (DDL persists outside sandbox)
  data = create_test_fixtures()

  on_exit(fn ->
    # Cleanup schemas after ALL tests in module
    cleanup_schemas()
    # Restore sandbox mode
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
  end)

  {:ok, data}
end

setup tags do
  # Each test gets its own sandbox checkout
  Haul.DataCase.setup_sandbox(tags)
  :ok
end
```

Key: DDL (CREATE SCHEMA) happens outside the Ecto sandbox. It's raw SQL. So provisioning in `setup_all` creates real schemas that persist across tests. Data within those schemas is visible to all tests via sandbox `:auto` mode or explicit shared checkout. Cleanup drops schemas after the entire module runs.

### Debounce Config Pattern

```elixir
# chat_live.ex
@extraction_debounce_ms Application.compile_env(:haul, :extraction_debounce_ms, 800)

# config/test.exs
config :haul, extraction_debounce_ms: 50
```

`compile_env` is correct here — the value is a module attribute used at compile time. Runtime `get_env` wouldn't work because `@extraction_debounce_ms` is resolved at compile.
