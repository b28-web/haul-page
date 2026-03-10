# T-033-03 Plan: Mock Service Layer

## Step 1: Refactor ChatSandbox for process isolation

**File:** `lib/haul/ai/chat/sandbox.ex`

Changes:
1. `set_response/1` — write to Process dictionary AND ETS keyed by `{self(), :response}`
2. `set_error/1` — write to Process dictionary AND ETS keyed by `{self(), :error}`
3. `clear_response/0` — delete from Process dictionary AND ETS
4. `clear_error/0` — delete from Process dictionary AND ETS
5. `send_message/2` — check Process.get first, fall back to ETS by self(), then default
6. `stream_message/3` — receives pid, look up `{pid, :response}` in ETS, then default
7. Remove global `:response` / `:error` keys from ETS

**Verify:** `mix test --stale` — chat tests should pass unchanged

## Step 2: Migrate worker test cleanup to Factories

**Files:** 7 test files (see structure.md)

For each file:
1. Add `alias Haul.Test.Factories` if not present
2. Replace inline `on_exit(fn -> ... query information_schema ... DROP SCHEMA ... end)` with `on_exit(fn -> Factories.cleanup_all_tenants() end)`

**Verify:** `mix test --stale`

## Step 3: Document mocking conventions

**File:** `docs/knowledge/test-architecture.md`

Add section "Mock the Boundary, Not Ash" after the existing "Adapter Switching" section:
- Principle: real DB for Ash, mocks only at external API boundaries
- The 8 mocked boundaries (7 compile-time adapters + Swoosh)
- Process isolation patterns used by each sandbox
- Rule: keep at least one integration test per module that exercises the full stack
- Anti-pattern: mocking Ash.read!/Ash.update! — fights the framework

**Verify:** No code change, manual review

## Step 4: Run full test suite

`mix test` — verify all 975 tests pass with no regressions.

## Testing Strategy

- **ChatSandbox refactor:** Existing chat tests (`chat_live_test.exs`, `chat_qa_test.exs`) implicitly verify the sandbox still works — they call `set_response/1` and `set_error/1` in setup
- **Cleanup migration:** Existing test assertions are unchanged — only the cleanup mechanism changes
- **No new tests needed:** The changes are infrastructure (sandbox internals, cleanup, docs), not new functionality
