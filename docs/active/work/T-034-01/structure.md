# T-034-01 Structure: stale-test-default

## Files Modified

### 1. `CLAUDE.md` — Test Targeting section (lines 93–165)

Changes:
- **Line 95**: Update intro to mention `mix test --stale` as default
- **Lines 99–114**: Reorder quick reference — `--stale` first, then file paths, then full suite
- **Lines 159–164**: Update rules — rule 1 becomes `mix test --stale`, add new rule for config caveat

No new sections. No structural changes to the table or tiers sections.

### 2. `docs/knowledge/rdspi-workflow.md` — Implement phase (line 41)

Change one line: replace "Run targeted tests after each change" with "Run `mix test --stale` after each change".

### 3. `.just/system.just` — Test section (after line 363)

Add `_test-stale` private recipe:
```
[private]
_test-stale *args='':
    mix test --stale {{ args }}
```

Update `_llm` recipe test-targeting line to mention `--stale`.

### 4. `justfile` — After `test-pyramid` recipe (after line 50)

Add public recipe:
```
# Run only tests affected by recent source changes
test-stale *args='':
    @just _test-stale {{ args }}
```

## Files NOT Modified

- No source code files
- No test files
- No config files
- `docs/knowledge/test-architecture.md` — not in scope (focuses on tier classification, not execution strategy)
