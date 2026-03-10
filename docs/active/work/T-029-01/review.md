# T-029-01 Review — Document Test Tiers

## Summary

Documentation-only ticket. Created a comprehensive test architecture guide and updated three existing files to reference it.

## Test Results

```
961 tests, 0 failures (1 excluded)
Finished in 92.0 seconds (3.6s async, 88.3s sync)
```

No regressions — expected since this is a documentation-only change.

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `docs/knowledge/test-architecture.md` | ~130 | Canonical 3-tier test guide |

## Files Modified

| File | Change |
|------|--------|
| `CLAUDE.md` | Added "Test tiers" subsection (table + rule) before Rules in § Test Targeting |
| `.just/system.just` | Added 1-line test tier summary to `_llm` Conventions section |
| `docs/knowledge/rdspi-workflow.md` | Added tier verification sentence to Review phase |

## Acceptance Criteria Check

- [x] `docs/knowledge/test-architecture.md` with 3-tier model, decision tree, examples, factory usage, setup_all guidance, async guidance, anti-patterns
- [x] CLAUDE.md updated with tier definitions + default-to-lowest rule + link
- [x] `just llm` output includes test tier summary
- [x] RDSPI review phase includes "lowest viable tier" check

## Test Coverage

N/A — documentation ticket, no code changes, no new tests needed.

## Open Concerns

None. All acceptance criteria met. The test-architecture.md uses concrete file paths from the current codebase; these will need updating if test files are renamed or reorganized.

## Verification

- `just llm` output confirmed to include test tier line
- All four target files verified to contain expected content
- Full test suite passes clean
