# T-031-02 Plan: verify-test-switching

## Steps

### Step 1: Add missing adapter entries to config/test.exs
Add `:chat_adapter` and `:cert_adapter` entries alongside the existing 5. These already default correctly but should be explicit for documentation purposes.

Verify: `mix test` still passes.

### Step 2: Add "Adapter Switching" section to test-architecture.md
Append after the "Anti-Patterns" section:
- How adapter dispatch works (compile_env → module attribute)
- Environment matrix table
- Step-by-step guide for adding a new adapter
- Recompilation requirement note

Verify: Documentation reads clearly and is accurate.

### Step 3: Run full test suite
Confirm 975+ tests pass with the config/test.exs addition.

## Testing Strategy

No new tests needed. This is a verification + documentation ticket. The existing test suite IS the verification — 975 tests exercising all adapter dispatch paths through sandbox adapters.
