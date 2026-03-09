# T-024-04 Progress: Agent Test Targeting

## Completed

- [x] Step 1: Added "Test Targeting" section to CLAUDE.md
  - Mapping table covering all 17 domain areas
  - Command examples (single file, directory, multi-path, line number)
  - Cross-cutting test guidance table
  - Rules: targeted during implement, full suite before review
- [x] Step 2: Updated RDSPI workflow
  - Implement phase: added targeted test guidance
  - Review phase: added full suite requirement
- [x] Step 3: Updated `just llm` briefing
  - Added test targeting convention line
- [x] Step 4: Verified targeted test timing
  - Content domain + page controller (58 tests): 7.2 seconds — under 15s target
  - Billing (30 tests): 0.06 seconds
  - Accounts + login + signup (37 tests): 5.0 seconds
- [x] Step 5: Full test suite
  - 746 tests, 0 failures (1 excluded)

## Remaining
None — all steps complete.

## Deviations
None — plan followed exactly.
