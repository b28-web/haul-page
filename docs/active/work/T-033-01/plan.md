# T-033-01 Plan: Audit Mock Candidates

## Steps

### Step 1: Write audit.md Section 1 — DataCase Files
Compile the per-test classification for all 27 DataCase files. Data already gathered in research phase from agent analysis of every file.

### Step 2: Write audit.md Section 2 — ConnCase Files
Compile the per-test classification for all 46 ConnCase files. Data gathered from agent analysis.

### Step 3: Write audit.md Section 3 — QA Overlap Report
List the ~30 overlapping test names between QA and non-QA files. Data from QA overlap agent.

### Step 4: Write audit.md Section 4 — Module-Level Action Items
Roll up per-test classifications into module recommendations with estimated time savings and target ticket assignments.

### Step 5: Verify completeness
Confirm every DataCase and ConnCase file appears in the audit. Cross-reference with the grep output from research.

## Testing Strategy

No code changes — no tests to run. Verification is completeness check against the file list.

## Commit Strategy

Single commit with audit.md + all RDSPI artifacts.
