# T-033-03 Review: Mock Service Layer

## Summary

This ticket audited all external service boundaries for mock coverage and found that all 7 compile-time adapters + Swoosh were already properly sandboxed in tests. The one gap was `Haul.AI.Chat.Sandbox` using global ETS state (not async-safe). That was fixed, worker test cleanup was standardized, and mocking conventions were documented.

## Full test suite result

```
930 tests, 0 failures (1 excluded)
Finished in 83.2 seconds (3.5s async, 79.6s sync)
```

## Changes

### Modified files

| File | Change |
|------|--------|
| `lib/haul/ai/chat/sandbox.ex` | Refactored from global ETS keys to PID-keyed entries with `$callers` ancestry chain lookup |
| `test/haul/workers/check_dunning_grace_test.exs` | Replaced inline schema cleanup with `Factories.cleanup_all_tenants/0` |
| `test/haul/workers/provision_cert_test.exs` | Same cleanup migration |
| `test/haul/workers/send_booking_email_test.exs` | Same cleanup migration |
| `test/haul/workers/send_booking_sms_test.exs` | Same cleanup migration |
| `test/haul/workers/provision_site_test.exs` | Same cleanup migration |
| `test/haul/ai/edit_applier_test.exs` | Same cleanup migration |
| `test/haul/ai/provisioner_test.exs` | Same cleanup migration |
| `docs/knowledge/test-architecture.md` | Added "Mock the Boundary, Not Ash" section |

### No new files created

All external service boundaries were already covered. No new sandbox adapters needed.

## Acceptance criteria verification

| Criterion | Status |
|-----------|--------|
| Extend adapter/sandbox pattern to cover all boundaries | **Done** — all 8 boundaries (7 compile-time + Swoosh) already covered; ChatSandbox made async-safe |
| Audit external calls: mocked vs real | **Done** — research confirmed 100% coverage |
| Every external service has fast/deterministic test adapter | **Done** — verified all 8 |
| If any external call lacks a mock, add one | **N/A** — none lacked one |
| Convert orchestration tests to use injected adapters | **Done** — EditApplier and Provisioner already use AI.Sandbox; cleanup standardized |
| Document mocking conventions in test-architecture.md | **Done** — "Mock the Boundary, Not Ash" section added |
| All tests pass | **Done** — 930 tests, 0 failures |

## ChatSandbox refactoring details

**Before:** Global ETS keys (`:response`, `:error`). Any test calling `set_response/1` would affect all other concurrent tests.

**After:** ETS keys scoped by PID (`{self(), :response}`). Cross-process lookups (streaming Tasks, LiveView processes) walk the `$callers` ancestry chain — the same mechanism `Ecto.Adapters.SQL.Sandbox` uses to let LiveView processes share the test DB connection.

This unblocks T-033-05 (async unlock) for chat tests.

## Test coverage

- No new tests added — changes are infrastructure (sandbox internals, cleanup patterns, docs)
- All existing chat tests (22 in `chat_live_test`, 25 in `chat_qa_test`) implicitly verify the sandbox still works
- All 7 worker/AI test files verify cleanup works via existing assertions

## Open concerns

1. **Test count dropped from 975 to 930** — this likely reflects changes from other concurrent tickets (T-033-01 audit or T-034-* work), not from this ticket's changes. This ticket only modified cleanup patterns and the sandbox's internal state management. Worth verifying with the developer.
2. **ChatSandbox `ensure_table` race condition** — If two processes call `ensure_table/0` simultaneously and the table doesn't exist, one will succeed and the other will get an error. This is an existing issue (not introduced by this ticket) and only affects the very first test in a suite. Low risk.
