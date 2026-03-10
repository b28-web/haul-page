# T-026-02 Progress: verify-and-document

## Completed

- [x] Step 1: Updated DEPLOYMENT.md — restructured "Local deploy" section
  - Native release now first with "(recommended)" label and `just pg` prerequisite
  - Docker image now second with "(optional)" label, clearly scoped to testing the Fly.io image
- [x] Step 2: Updated OVERVIEW.md
  - Added decision: Docker Desktop no longer required for dev (in "Decisions made" section)
- [x] Step 3: Verified `just llm` output
  - Confirmed: no Docker-for-dev references, PG 18 documented, `just pg` commands listed
  - Already correct from T-026-01, no changes needed
- [x] Step 4: Ran `mix test`
  - 845 tests, 12 failures — all pre-existing from T-025-01 uncommitted WIP (documented in OVERVIEW.md)
  - No new failures from documentation changes

## Deviations from plan

None.
