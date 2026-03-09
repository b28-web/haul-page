# T-024-03 Review: Fix Slow Tests

## Summary

Reduced test suite runtime from **172.9s → 78.5s** (54.6% reduction). All 746 tests pass with 0 failures across 3 consecutive runs. No flaky tests introduced.

## Changes

### Production Code (2 files)
- **`lib/haul_web/live/chat_live.ex`** — Made `@extraction_debounce_ms` and `@max_messages` configurable via `Application.compile_env`. Added `max_messages` socket assign for template access. Fixed hardcoded `>= 50` template check to use the assign.
- **`config/test.exs`** — Added `bcrypt_elixir: log_rounds: 1`, `extraction_debounce_ms: 50`, `max_chat_messages: 10`.

### Test Infrastructure (1 file)
- **`test/support/conn_case.ex`** — Replaced `sign_in_with_password` (bcrypt verify + DB read) with `AshAuthentication.Jwt.token_for_user` (direct JWT generation) in `create_authenticated_context/1`.

### Test Files (6 files modified)
- **`test/haul_web/live/chat_qa_test.exs`** — Reduced sleeps from 1500ms → 200ms, 500ms → 150ms. Updated rate-limit test to use config-driven max messages.
- **`test/haul_web/live/chat_live_test.exs`** — Same sleep and rate-limit adjustments.
- **`test/haul_web/live/provision_qa_test.exs`** — Reduced one 500ms sleep to 200ms.
- **`test/haul_web/controllers/qr_controller_test.exs`** — Changed to `async: true`.
- **`test/haul_web/controllers/health_controller_test.exs`** — Changed to `async: true`.
- **`test/haul/rate_limiter_test.exs`** — Changed to `async: true`.

## Test Coverage

- **746 tests, 0 failures** (unchanged count)
- No tests deleted or stubbed
- Rate-limit tests still verify the actual limit enforcement, just at 10 messages instead of 50
- Chat extraction tests still verify the full debounce → extract → render pipeline, just faster
- Async-converted tests verified to not share state (unique keys, no DB, no tenant schemas)

## Before/After Timing (Top 10 Files)

| File | Before | After | Savings |
|------|--------|-------|---------|
| chat_qa_test.exs | 22.5s | 4.1s | -81.8% |
| chat_live_test.exs | 13.0s | 2.8s | -78.5% |
| preview_edit_test.exs | 8.0s | 5.9s | -26.3% |
| security_test.exs | 7.9s | 2.0s | -74.7% |
| domain_settings_live_test.exs | 7.9s | 2.5s | -68.4% |
| onboarding_live_test.exs | 7.7s | 2.9s | -62.3% |
| billing_qa_test.exs | 7.6s | 2.4s | -68.4% |
| provision_qa_test.exs | 7.4s | 5.0s | -32.4% |
| domain_qa_test.exs | 6.7s | 2.1s | -68.7% |
| billing_live_test.exs | 6.5s | 2.2s | -66.2% |

## Open Concerns

### 60s Target Not Met
Final runtime: 78.5s vs 60s target. The remaining 18.5s is structural:
- ~25 test files create a PostgreSQL schema per test (~90-100ms each, ~200 calls total)
- Schema creation is DDL that bypasses Ecto sandbox rollback
- Moving to `setup_all` requires fundamentally restructuring test isolation in these files
- Per the ticket's non-goals ("Don't stub out real behavior"), this tradeoff is acceptable

### Production Code Change
The `compile_env` change in `chat_live.ex` means the debounce and max_messages values are compiled into the module. A recompile is needed after config changes. This is standard Elixir practice for module-level constants.

### Rate-Limit Test Reduction
Tests now loop 10 times instead of 50. This still validates the rate limiter works, but with fewer iterations. If a regression appears only at higher counts, these tests won't catch it. The `RateLimiter` module itself is unit-tested separately with arbitrary limits.

## Files Not Changed
- No admin LiveView test files (services, gallery, endorsements, etc.) were modified — they benefit from bcrypt + JWT improvements automatically
- No test files deleted
- No stubs or mocks added
- test_helper.exs unchanged
- data_case.ex unchanged
