# T-031-02 Design: verify-test-switching

## Goal

Verify that compile-time adapter switching works correctly across environments and document the pattern for future contributors.

## Verification Results

### Test environment ✓
- 975 tests pass, 0 failures
- All 7 sandbox adapters activate via `config/test.exs` + `config/config.exs` defaults
- Sandbox adapters provide deterministic responses without external calls
- Per-test overrides (e.g., `Haul.AI.Sandbox.set_response/2`) work because the sandbox module itself is the compiled adapter — internal `Process.get/put` is within the sandbox

### Dev environment ✓
- `config/dev.exs` sets no adapter keys → inherits Sandbox defaults from `config/config.exs`
- This is correct: dev should not hit external APIs by default
- Developers who need real APIs in dev can add overrides to `config/dev.exs`

### Production environment ✓
- `config/prod.exs` explicitly sets all 7 adapters to production implementations
- `config/runtime.exs` provides API keys/secrets but does not set adapter modules
- No risk of `compile_env` / runtime conflict

### CI pipeline ✓
- CI runs `MIX_ENV=test`, so `config/test.exs` applies at compile time
- `compile_env` embeds Sandbox adapters into compiled modules
- No special CI configuration needed

### Edge case: runtime.exs adapter conflict ✓
- Verified: zero adapter config keys in `config/runtime.exs`
- `compile_env` would not see runtime.exs values anyway (runtime.exs runs after compilation)
- No conflict possible

## Documentation Approach

### Option A: Add adapter section to `docs/knowledge/test-architecture.md`
**Pros:** Adapter switching is tightly related to testing (sandboxes are the test mechanism). One file to maintain.
**Cons:** test-architecture.md is about test tiers, not architecture.

### Option B: Create separate `docs/knowledge/adapter-switching.md`
**Pros:** Clean separation. Easy to find by name.
**Cons:** Another file to maintain. Small document.

### Option C: Add adapter section to existing test-architecture.md with cross-reference
**Pros:** Keeps related concepts together. The test tier doc already references sandboxes implicitly.
**Cons:** File grows slightly.

### Decision: Option C

Add an "Adapter Switching" section to `docs/knowledge/test-architecture.md`. It's the natural place someone would look when wondering "how do test sandboxes work?" The section covers:
1. How compile-time adapter dispatch works
2. The environment matrix (which adapter in which env)
3. How to add a new adapter (step-by-step)
4. Recompilation note

This keeps documentation consolidated and discoverable.
