# T-024-03 Progress: Fix Slow Tests

## Completed Steps

### Step 1: Bcrypt rounds reduction ✓
- Added `config :bcrypt_elixir, log_rounds: 1` to `config/test.exs`
- Reduces password hashing from ~30ms to <1ms per call

### Step 2: Configurable extraction debounce ✓
- Changed `@extraction_debounce_ms` in `chat_live.ex` to `Application.compile_env(:haul, :extraction_debounce_ms, 800)`
- Set to 50ms in test.exs (800ms in production)

### Step 3: Configurable max chat messages ✓
- Changed `@max_messages` in `chat_live.ex` to `Application.compile_env(:haul, :max_chat_messages, 50)`
- Set to 10 in test.exs (50 in production)
- Added `@max_messages` as socket assign for template access
- Fixed hardcoded `>= 50` in template to use `@max_messages` assign

### Step 4: Reduce chat test sleeps ✓
- `chat_qa_test.exs`: All `Process.sleep(1500)` → 200ms, `Process.sleep(500)` → 150ms
- `chat_live_test.exs`: Same sleep reductions
- Rate-limit tests: Updated loop counts from hardcoded 50 to `Application.get_env(:haul, :max_chat_messages, 50)` (now 10 in test)
- `provision_qa_test.exs`: Reduced 500ms sleep to 200ms

### Step 5: Async conversions ✓
- `qr_controller_test.exs`: → `async: true`
- `health_controller_test.exs`: → `async: true`
- `rate_limiter_test.exs`: → `async: true`
- `chat_test.exs`: Kept `async: false` (ChatSandbox uses global ETS)

### Step 6: JWT token optimization ✓
- Replaced `sign_in_with_password` in `create_authenticated_context/1` with `AshAuthentication.Jwt.token_for_user/1`
- Eliminates redundant bcrypt verify on every test setup

### Steps 7-8: `setup_all` migration — DEFERRED
- Detailed analysis showed that security_test, tenant_isolation_test, and most admin tests mutate setup data (create users, update roles, create records)
- `setup_all` would require splitting DDL from data creation and restructuring test isolation
- Risk of introducing flaky tests outweighs the ~4s potential savings

## Results

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Total wall clock | 172.9s | 78.5s | **-54.6%** |
| Chat tests (2 files) | 35.4s | 6.8s | -80.8% |
| Sync file time | 170.6s | 77.5s | -54.6% |
| Async file time | 1.1s | 1.0s | ~same |
| Tests | 746 | 746 | 0 change |
| Failures | 0 | 0 | 0 change |

## What's Left

The remaining ~18s gap to the 60s target comes from per-test tenant provisioning across ~25 admin LiveView test files. Each creates a company, provisions a PostgreSQL schema (DDL), and creates users per-test. This costs ~90-100ms per test × ~200 tests = ~18-20s.

Closing this gap would require either:
1. **Shared tenant fixtures** — create schemas in `setup_all`, share across tests. Requires restructuring all admin test files and careful sandbox handling. Risk: data leaks, flaky tests.
2. **Schema template cloning** — pre-create one tenant schema, clone structure for each test. PostgreSQL doesn't natively support schema cloning.
3. **Per-module cleanup** — drop schemas per-module instead of per-test. Requires unique company names and data isolation changes across all affected files.

None of these are achievable without test isolation risk per the ticket's non-goals.
