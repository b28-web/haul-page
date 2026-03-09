# T-024-03 Plan: Fix Slow Tests

## Step 1: Bcrypt rounds reduction

**Files:** `config/test.exs`
**Change:** Add `config :bcrypt_elixir, log_rounds: 1`
**Verify:** `mix test test/haul/accounts/user_test.exs` — all pass, noticeably faster
**Expected savings:** ~6s across full suite

## Step 2: Configurable extraction debounce

**Files:** `lib/haul_web/live/chat_live.ex`, `config/test.exs`
**Changes:**
- chat_live.ex: `@extraction_debounce_ms Application.compile_env(:haul, :extraction_debounce_ms, 800)`
- test.exs: `config :haul, extraction_debounce_ms: 50`
**Verify:** `mix test test/haul_web/live/chat_live_test.exs` — passes, faster

## Step 3: Configurable max chat messages

**Files:** `lib/haul_web/live/chat_live.ex`, `config/test.exs`
**Changes:**
- chat_live.ex: `@max_messages Application.compile_env(:haul, :max_chat_messages, 50)`
- test.exs: `config :haul, max_chat_messages: 10`
**Verify:** Chat rate-limit tests still enforce the limit, just at 10 instead of 50
**Note:** Must update rate-limit test assertions to use 10 instead of hardcoded 50

## Step 4: Reduce chat test sleeps

**Files:** `test/haul_web/live/chat_qa_test.exs`, `test/haul_web/live/chat_live_test.exs`
**Changes:**
- `Process.sleep(1500)` → `Process.sleep(200)` (50ms debounce + buffer)
- `Process.sleep(500)` → `Process.sleep(150)`
- `Process.sleep(300)` → `Process.sleep(150)`
- Rate-limit loop adjustments: update message counts from 50 to 10
**Verify:** `mix test test/haul_web/live/chat_qa_test.exs test/haul_web/live/chat_live_test.exs`

## Step 5: Async conversions

**Files:** 4 test files
**Changes:** `async: false` → `async: true` in use declarations
**Verify:** `mix test` on each file individually, then together

## Step 6: `setup_all` for security_test.exs

**File:** `test/haul/accounts/security_test.exs`
**Changes:**
- Rename `setup do` to `setup_all do`
- Keep `on_exit` schema cleanup (runs after all tests)
- Add per-test `setup` block that calls `Haul.DataCase.setup_sandbox(tags)` with `tags` from context
- Return shared context from `setup_all`
**Verify:** `mix test test/haul/accounts/security_test.exs` — all 11 pass

## Step 7: `setup_all` for tenant_isolation_test.exs

**File:** `test/haul/tenant_isolation_test.exs`
**Same pattern as Step 6.**
**Verify:** `mix test test/haul/tenant_isolation_test.exs` — all 10 pass

## Step 8: `setup_all` for dashboard_live_test.exs

**File:** `test/haul_web/live/app/dashboard_live_test.exs`
**Changes:** Move `create_authenticated_context()` to `setup_all`, keep per-test sandbox setup
**Verify:** `mix test test/haul_web/live/app/dashboard_live_test.exs`

## Step 9: Full suite verification

**Command:** `mix test`
**Criteria:**
- All 746+ tests pass
- 0 failures
- Note wall-clock time for before/after comparison

## Step 10: Timing telemetry run

**Command:** `HAUL_TEST_TIMING=1 mix test`
**Capture:** Total runtime, top 10 slowest files, compare with T-024-02 baseline
**Document:** Before/after numbers in progress.md

## Testing Strategy

- Each step is verified independently before moving on
- Steps 1-3 are config/production code changes — verify with targeted tests
- Steps 4-8 are test-file changes — verify with the specific file
- Step 9 is the full regression check
- Step 10 is measurement

## Risk Mitigation

- If `setup_all` causes flaky tests, revert to per-test `setup` for that file
- If sleep reductions cause flaky tests, increase sleep values incrementally
- If async conversion causes failures, revert to sync
- Run full suite at least twice to check for flakiness
