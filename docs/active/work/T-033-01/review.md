# T-033-01 Review: Audit Mock Candidates

## Test Suite

`mix test` — **975 tests, 0 failures**, 104.1s (3.7s async, 100.4s sync). No code changes in this ticket.

## Changes

### Files created
- `docs/active/work/T-033-01/audit.md` — Main deliverable. Four-section audit covering all 73 DataCase+ConnCase files.
- `docs/active/work/T-033-01/research.md` — Raw data collection.
- `docs/active/work/T-033-01/design.md` — Classification criteria decisions.
- `docs/active/work/T-033-01/structure.md` — Output format definition.
- `docs/active/work/T-033-01/plan.md` — Implementation steps.
- `docs/active/work/T-033-01/progress.md` — Implementation tracking.

### Files modified
None. This is a research-only ticket.

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| Table covering every DataCase and ConnCase test file | Done (27 DataCase + 46 ConnCase) |
| Each test classified as DB-required / mock-feasible / render-only | Done |
| Flag files where entire module can drop to ExUnit.Case async:true | Done (6 files flagged) |
| Flag files where some tests can split to unit module | Done (3 files: onboarding, seeder, cost_tracker) |
| Flag QA files overlapping with non-QA (list test names) | Done (30 overlaps across 3 pairs) |
| Estimate per-file time savings | Done in Section 4 action items |

## Key Findings

1. **30 QA tests are duplicates** of non-QA tests (chat: 11, billing: 10, domain: 9). Removing these saves ~5.5s.
2. **18 worker/AI tests** use DB only for setup, not verification. Mocking Ash lookups makes them async-safe.
3. **19 pure-function tests** are trapped in DataCase modules (slug derivation, cost math, YAML parsing).
4. **63 tests** across 6 files can flip to async:true with minimal changes.
5. Combined savings estimate: ~14.9s, bringing suite from ~93s toward the ≤60s target.

## Open Concerns

- **Ash validation test classification**: The ticket says keep these as DB-required. This is conservative — many Ash validations are deterministic and could theoretically be tested via changeset inspection. If T-033-03 finds a clean pattern for Ash changeset testing, more tests could move to unit tier.
- **impersonation_test.exs at 2.6s despite async:true**: This file is slow for its tier. Not in scope for this ticket but worth investigating.
- **chat_live_test vs chat_qa_test**: These are nearly identical (22 vs 25 tests, 11 overlapping). After dedup, consider merging the remaining QA-only tests into chat_live_test.
- **Wall-clock variability**: Suite ran at 92.7s and 104.1s across two runs. Per-test timings are stable but total varies with system load.
