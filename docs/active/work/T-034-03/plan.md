# T-034-03 Plan: agent-test-targeting

## Steps

### Step 1: Add `test-file` recipe to `.just/system.just`

Add `_test-file` private recipe after the existing `_test-stale` block.

**Verify:** `just test-file test/haul_web/smoke_test.exs` runs and completes.

### Step 2: Add `test-file` public recipe to `justfile`

Add `test-file` entry after `test-stale`, with comment.

**Verify:** `just --list` shows the new recipe.

### Step 3: Update RDSPI implement phase

Replace the `mix test --stale` sentence in the Implement section with the three-sentence version that:
- Explicitly says "not `mix test`"
- Adds domain-targeting guidance with CLAUDE.md reference
- Says full suite is for Review phase only

**Verify:** Read the file, confirm wording is correct.

### Step 4: Verify from agent shell

Run `just test-stale --max-failures 1` and `just test-file test/haul_web/smoke_test.exs` to confirm both work with mise shims.

## Testing strategy

No automated tests — this is justfile + docs only. Manual verification that recipes execute correctly.
