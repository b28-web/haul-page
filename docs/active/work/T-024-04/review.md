# T-024-04 Review: Agent Test Targeting

## Summary

Documentation-only ticket. Added test targeting guidance so agents can run relevant tests during implementation instead of the full 746-test suite (~96s) every time.

## Changes

### Modified files

| File | Change |
|------|--------|
| `CLAUDE.md` | Added "Test Targeting" section (~60 lines): source→test mapping table (17 domains), command examples, cross-cutting test table, rules |
| `docs/knowledge/rdspi-workflow.md` | Added 1 sentence to Implement phase (run targeted tests) and 1 sentence to Review phase (run full suite) |
| `.just/system.just` | Added 1 line to `_llm` recipe: test targeting convention reference |

### No files created or deleted (outside work artifacts)

## Acceptance criteria verification

| Criterion | Status |
|-----------|--------|
| Document convention for targeted tests (file, multi-file, tag-based) | ✅ CLAUDE.md § Test Targeting with examples |
| Mapping file/section: source modules → test files | ✅ 17-row mapping table in CLAUDE.md |
| Mapping: stories/domains → test file globs | ✅ Domain column maps to test directories |
| Update RDSPI: targeted tests during implement | ✅ Sentence added to Implement phase |
| Update RDSPI: full suite before review | ✅ Sentence added to Review phase |
| Targeted runs under 15 seconds | ✅ Verified: 0.06s–7.2s for typical scopes |

## Test coverage

No code changes, so no new tests needed. Full suite: **746 tests, 0 failures** (1 excluded: `@moduletag :baml_live`).

## Design decisions

- **Static mapping table over script/tags**: The problem is information asymmetry (agents don't know which tests to run), not tooling. A table in CLAUDE.md is zero-maintenance and agents already read it.
- **No ExUnit domain tags**: The codebase's 1:1 directory mirroring makes file-path targeting equivalent to tag targeting, with no maintenance burden.
- **Cross-cutting test table**: Separate from the main mapping because these apply conditionally (only when touching shared infrastructure).

## Open concerns

- **Mapping table maintenance**: When new domains or test files are added, the table in CLAUDE.md must be updated manually. This is low-risk since agents adding new domains will see the section and can update it.
- **Tag-based targeting not implemented**: The ticket mentioned `--only tag:billing` as a possibility. We did not add domain tags because file-path targeting is equivalent for this codebase. Tags could be added later if the test structure becomes more complex.

## No critical issues requiring human attention.
