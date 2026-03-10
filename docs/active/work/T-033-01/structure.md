# T-033-01 Structure: Audit Mock Candidates

## Output Artifact

Single file: `docs/active/work/T-033-01/audit.md`

### Format

The audit has four sections, each a markdown table:

#### Section 1: DataCase Files
Columns: File | Tests | Time | DB-Required | Mock-Feasible | Pure-Unit | Module Recommendation | Notes

#### Section 2: ConnCase Files
Columns: File | Tests | Time | DB-Required | Render-Only | Mock-Feasible | Module Recommendation | Notes

#### Section 3: QA Overlap Report
Columns: QA File | QA Test Name | Non-QA Counterpart File | Overlapping Test Name | Verdict (remove/keep/merge)

#### Section 4: Module-Level Action Items
Columns: File | Current Tier | Recommended Action | Estimated Savings | Target Ticket

### Module Recommendations (values)

- **KEEP** — All tests are DB-required, no changes needed
- **SPLIT** — Some tests can extract to a new ExUnit.Case module
- **MOCK** — Module benefits from Mox/sandbox pattern for service layer
- **ASYNC** — Can flip to async:true with no other changes
- **DEDUP** — QA file overlaps with non-QA; remove/merge specific tests

### Target Ticket mapping

- T-033-02: SPLIT recommendations (extract pure logic)
- T-033-03: MOCK recommendations (service layer mocks)
- T-033-04: DEDUP recommendations (QA overlap)
- T-033-05: ASYNC recommendations (flip async:true)

## No Code Changes

This ticket produces only `audit.md`. No source files modified.
