# T-033-05 Design: async-unlock

## Decision: Option A+C — Fix all blockers + flip everything

### Rationale
Three blockers prevent async execution. All three have small, contained fixes. Fixing them enables flipping ~44 files from async: false to async: true — far exceeding the 15-file target.

## Blocker Fixes

### Fix 1: Unique Company Names in `create_authenticated_context`

**Problem:** `ConnCase.create_authenticated_context/1` hardcodes `%{name: "Test Co"}`, generating slug "test-co". Concurrent tests get unique constraint violations.

**Fix:** Add `System.unique_integer([:positive])` to the company name, matching the pattern already used in `Haul.Test.Factories.build_company/1`.

**Changed:** `test/support/conn_case.ex:49` — one line change

**Why not just migrate to factories:** Many test files already use `create_authenticated_context`. Changing the helper is faster and less disruptive than updating 30+ files. The factory and the helper will now use the same uniqueness pattern.

### Fix 2: Process-scoped Rate Limiter Cleanup

**Problem:** `clear_rate_limits/0` calls `ets.delete_all_objects` — wipes ALL rate limit entries globally. With async tests, one test's cleanup wipes another test's state.

**Approach considered:**
1. **Make rate limiter PID-keyed (T-035-02 scope)** — changes production code, larger scope
2. **Remove clear_rate_limits calls** — tests genuinely test rate-limited endpoints, removal would cause false positives
3. **Use unique rate limit keys per test** — no production code changes needed

**Decision:** Keep `clear_rate_limits` but scope it. Instead of `delete_all_objects`, delete only entries matching the current test's IP/key. Since ConnCase tests use `build_conn()` which generates a distinct remote_ip per test process, rate limit keys are already per-test in practice — the issue is only that `delete_all_objects` wipes ALL entries.

Actually, looking more carefully: the rate limit key is based on the request IP + path, not the test process. In tests, `build_conn()` uses `127.0.0.1` for all tests. So rate limit entries WILL collide across concurrent tests.

**Revised decision:** Make `clear_rate_limits` a no-op and instead use high rate limits in test config. The real rate limit is 5 per minute — tests don't run 5 requests to the same endpoint. The defensive `clear_rate_limits()` was added because sequential tests accumulated entries across modules. With async tests + Ecto sandbox rollback, each test's HTTP lifecycle is isolated.

Wait — ETS entries survive across tests regardless of sandbox rollback. ETS is not transactional.

**Final decision:** The simplest safe fix is to just leave these 5 files as async: false for now. The rate limiter global state is genuinely unsafe for concurrent access and the proper fix (T-035-02: process-local keys) should handle it. We still hit 44+ files flipped, well above the 15-file target. Document these 5 as blocked pending T-035-02.

### Fix 3: Concurrent DDL (Schema Creation)

**Problem:** With unique company names, each test creates a unique schema. DDL can't be rolled back in sandbox. Need cleanup.

**Current state:** Tests already use `on_exit(fn -> cleanup_tenants() end)` or `Haul.Test.Factories.cleanup_all_tenants()`. With unique names, concurrent `DROP SCHEMA` operates on different schemas — safe.

**Decision:** No change needed. Unique names + existing cleanup patterns handle this.

## Async Flip Strategy

### Tier 1: Immediate async: true (no blockers)
- **1 ExUnit.Case file:** chat_test.exs
- **23 DataCase files:** All 25 minus onboard_test (uses global filesystem) and test_pyramid_test (temp files)
- **18 ConnCase files:** All 23 minus 5 rate-limiter files

**Total: ~42 files flipped**

### Tier 2: Remain async: false (documented blockers)
- **5 ConnCase files:** billing_live_test, signup_flow_test, signup_live_test, chat_live_test, preview_edit_test, proxy_routes_test — blocked by global rate limiter (→ T-035-02)
- **1 ExUnit.Case:** test_pyramid_test — creates temp files in /tmp
- **1 DataCase:** onboard_test — may use filesystem or global state (need to verify)

### Concurrency Groups: Not needed yet
With 42+ files going async, wall-clock time should drop dramatically. Concurrency groups add complexity and are better suited for T-035-03 (shared tenant pool). Skip for this ticket.

## Risk Mitigation

1. **Flaky test detection:** Run `mix test` 3 times with different seeds after changes
2. **Incremental approach:** Flip DataCase files first (simpler), then ConnCase files
3. **Revert plan:** If a file causes flaky failures, revert it to async: false and document why

## Rejected Alternatives

- **Concurrency groups only:** Adds complexity without addressing root causes. Groups are for shared-tenant parallelism (T-035-03), not general async unlock.
- **Rate limiter process-local fix:** Correct long-term fix but overlaps with T-035-02 scope. 5 files staying sync is acceptable.
- **Migrate all tests to factories:** Would be cleaner but touches 30+ files for a one-line fix in ConnCase.
