# T-034-01 Plan: stale-test-default

## Implementation Steps

### Step 1: Add `just test-stale` recipe

Add `_test-stale` to `.just/system.just` and `test-stale` to `justfile`.

**Verify:** `just test-stale` runs without error (should report 0 tests if nothing is stale).

### Step 2: Update CLAUDE.md Test Targeting section

- Update intro line (95)
- Reorder quick reference to put `--stale` first
- Update rules: rule 1 → `mix test --stale`, add config caveat rule
- Add note explaining how `--stale` works

**Verify:** Read back the section, confirm it's clear and complete.

### Step 3: Update RDSPI workflow

- Change implement phase line 41 to reference `mix test --stale`

**Verify:** Read back, confirm review phase still says `mix test`.

### Step 4: Update `just llm` briefing

- Update the test-targeting line in `_llm` recipe to mention `--stale`

**Verify:** Run `just llm`, confirm it mentions `--stale`.

### Step 5: Verify `--stale` works

- Touch a source file, run `mix test --stale`, confirm only related tests run
- Run `mix test --stale` with no changes, confirm it reports nothing to run

## Testing Strategy

This is a documentation-only ticket. Verification is behavioral:
1. `just test-stale` recipe exists and runs
2. `mix test --stale` correctly identifies changed dependencies
3. Full suite still passes (`mix test`)
