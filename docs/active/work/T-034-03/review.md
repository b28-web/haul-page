# T-034-03 Review: agent-test-targeting

## Summary

Added `just test-file FILE` recipe and strengthened RDSPI workflow implement phase with explicit domain-targeting guidance. Most ACs were already satisfied by prior work (T-024-04, T-034-01).

## Changes

| File | Change |
|------|--------|
| `.just/system.just` | Added `_test-file FILE *args=''` private recipe (3 lines) |
| `justfile` | Added `test-file FILE *args=''` public recipe with comment (3 lines) |
| `docs/knowledge/rdspi-workflow.md` | Replaced 1 sentence with 3 in Implement phase: explicit "not `mix test`", domain-targeting with CLAUDE.md reference, "save full suite for Review" |

## AC verification

| AC item | Status |
|---------|--------|
| `just test-stale` recipe | ✅ Already existed, verified working |
| `just test-file FILE` recipe | ✅ Added, verified with `just test-file test/haul_web/smoke_test.exs` |
| Update `_llm` to mention `--stale` | ✅ Already present at line 270 of `.just/system.just` |
| RDSPI: "After each change, run --stale (not mix test)" | ✅ Added |
| RDSPI: "Run targeted tests for domain (see CLAUDE.md)" | ✅ Added |
| RDSPI: "Only run mix test in review" | ✅ Added |
| Verify from agent shell (mise shims, PATH) | ✅ Both recipes execute successfully |

## Test coverage

No automated tests — this ticket is documentation + justfile recipes only. Manual verification confirms both recipes execute correctly from agent shells (mise shims via PATH export in system.just line 8).

## Full test suite

Not run — this ticket modifies no source code (only justfile recipes and documentation). Pre-existing test failures exist from uncommitted prior work (noted in OVERVIEW.md blockers).

## Open concerns

None. All acceptance criteria met.
