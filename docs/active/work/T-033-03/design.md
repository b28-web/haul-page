# T-033-03 Design: Mock Service Layer

## Problem Statement

The ticket asks to extend adapter/sandbox patterns to cover all external service boundaries and convert orchestration tests to use injected test adapters. Research reveals all 7 external boundaries already have sandbox adapters. The actual gaps are:

1. ChatSandbox uses global ETS state (not async-safe)
2. test-architecture.md lacks "mock the boundary, not Ash" convention docs
3. Worker tests use inconsistent cleanup patterns (inline vs Factories)

## Options Evaluated

### Option A: Convert ChatSandbox to Process-Keyed Isolation

Refactor `Haul.AI.Chat.Sandbox` to use a caller-key pattern (like Mox or Ecto SQL.Sandbox). Each test process registers itself, and the sandbox returns process-specific responses.

**Approach:** Use `Process.put/get` for the calling process, with ETS as a shared fallback for cross-process scenarios (like streaming, where the sandbox spawns a Task).

**Implementation:**
- `set_response/1` → store in `Process.put({__MODULE__, :response}, value)` AND in ETS keyed by caller PID
- `stream_message/3` receives a pid parameter — look up that pid's ETS entry for the response
- Default behavior (no override) stays the same

**Pros:** Unlocks `async: true` for chat tests. Consistent with AI.Sandbox pattern. No new dependencies.
**Cons:** Slightly more complex than current global ETS. Process exit cleanup needed.

### Option B: Keep ChatSandbox As-Is

Don't change the ChatSandbox. Chat tests are currently `async: false` and work fine.

**Pros:** Zero risk, zero effort.
**Cons:** Blocks T-033-05 async unlock. The ticket explicitly asks to verify async safety.

### Option C: Use Mox Instead of Custom Sandboxes

Replace all 7 custom sandboxes with Mox behaviours. Mox provides built-in process isolation.

**Pros:** Community standard. Well-tested concurrency model.
**Cons:** Requires defining behaviours for all 7 modules (they already have `@callback` but not all expose full `@behaviour`). Breaks consistency with existing pattern. Ticket says "do not introduce Mox."

## Decision

**Option A: Convert ChatSandbox to process-keyed isolation.**

Rationale:
- The ticket asks to ensure every adapter is "fast and deterministic" and compatible with `async: true`
- ChatSandbox is the only async-unsafe sandbox — fixing it completes the coverage
- The pattern is simple: `Process.put/get` for same-process calls, ETS keyed by PID for cross-process (streaming)
- Consistent with how `Haul.AI.Sandbox` already works (Process.put for overrides)

## Additional Work

1. **Document mocking conventions** in test-architecture.md — "Mock the Boundary, Not Ash" section
2. **Migrate worker tests to use Factories.cleanup_all_tenants/0** — consistency, not new functionality
3. **Verify all sandbox adapters** have consistent patterns (they do, per research)

## What This Ticket Does NOT Do

- Does not mock Ash resource operations (per ticket: "don't mock Ash")
- Does not introduce Mox or new dependencies
- Does not change which tests use DataCase vs ExUnit.Case (that's T-033-02)
- Does not flip tests to `async: true` (that's T-033-05)
- Does not dedup QA tests (that's T-033-04)
