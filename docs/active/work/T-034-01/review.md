# T-034-01 Review: stale-test-default

## Summary

Made `mix test --stale` the default testing command during the implementation phase for all agents. This is a documentation/workflow-only change — no source code modified.

## Full Test Suite Result

```
975 tests, 0 failures (1 excluded)
Finished in 93.3 seconds
```

## Verification of `--stale`

- Modified `lib/haul/billing.ex` → `mix test --stale` ran 484 tests (correctly scoped subset)
- Clean state → `mix test --stale` reports "No stale tests"
- `just test-stale` recipe works as expected

## Files Modified

| File | Change |
|------|--------|
| `CLAUDE.md` | Test Targeting section: `--stale` as default, quick reference reordered, config caveat rule added |
| `docs/knowledge/rdspi-workflow.md` | Implement phase: "Run `mix test --stale` after each change" |
| `.just/system.just` | Added `_test-stale` recipe; updated `_llm` test-targeting line |
| `justfile` | Added public `test-stale` recipe |

## Test Coverage

N/A — documentation-only ticket. No new tests needed. Existing 975 tests unaffected.

## Acceptance Criteria Check

- [x] CLAUDE.md updated: `mix test --stale` as default during implementation
- [x] CLAUDE.md updated: `mix test` for full suite before review
- [x] CLAUDE.md updated: documents compile-time tracing mechanism
- [x] RDSPI workflow updated: implementation phase uses `mix test --stale`
- [x] RDSPI workflow: review phase already specifies `mix test` (unchanged)
- [x] `just test-stale` recipe added as convenience alias
- [x] Verified `--stale` runs only related tests when source file changes
- [x] Config caveat documented (rule 3 in CLAUDE.md rules)

## Open Concerns

- **`--stale` ran 484/975 tests for a single file change** — this is higher than expected (5–15s estimate in ticket). The billing module is heavily depended upon, so many tests transitively depend on it. For typical ticket-scoped changes (touching 2–5 files in a single domain), the count will be much lower. The 5–15s estimate applies to focused changes, not to core modules.
- **`--stale` doesn't detect config changes** — documented as rule 3. Agents must remember to run full suite when changing config.
