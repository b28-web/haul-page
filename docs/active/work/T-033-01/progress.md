# T-033-01 Progress

## Completed

1. Ran `mix test --trace` — 975 tests, 0 failures, 92.7s
2. Classified all 27 DataCase files (169 tests): 106 DB-required, 49 mock-feasible, 19 pure-unit
3. Classified all 46 ConnCase files (448 tests): 216 DB-required, 164 render-only, 15 mock-feasible, 55 already async
4. Identified 30 QA/non-QA overlapping tests across 3 file pairs
5. Produced module-level action items for T-033-02 through T-033-05
6. Wrote audit.md with all four sections

## Deviations

- Ash validation tests classified as DB-required per ticket instruction, even though they look like pure validation. This reduces the mock-feasible count significantly for content resource tests.
- impersonation_test.exs (2.6s, async:true) was noted as potentially slow for its tier but not flagged for action since it's already async.
