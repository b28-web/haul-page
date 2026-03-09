# T-024-02 Plan: Timing Analysis

## Steps

### Step 1: Write analysis.md — Executive Summary
- Runtime breakdown: 173s total, 4s compile, 169s sync execution
- Key finding: 51% of time is redundant per-test setup
- Key finding: 21% is chat sleep overhead

### Step 2: Write analysis.md — Detailed Breakdowns
- Top 10 slowest files table with per-test averages
- Async audit: every `async: false` file with reason
- Setup cost: per-test overhead from `create_authenticated_context()` and tenant provisioning
- Sleep inventory: every `Process.sleep` call with file, count, and total time

### Step 3: Write analysis.md — Bottleneck Categories
- Categorize all 85 test files into: inherently slow, fixable setup, could-be-async, sleep overhead, already fast

### Step 4: Write analysis.md — Prioritized Fix List
- Tier 1 fixes with per-file estimated savings
- Tier 2-4 fixes with aggregate estimates
- Projected runtime after each tier

### Step 5: Verify completeness against acceptance criteria
- Top 10 slowest files with per-test breakdown ✓
- Async audit ✓
- Setup cost analysis ✓
- Compilation vs execution ✓
- Categorized bottlenecks ✓
- Prioritized fix list ✓
- Projected runtime ✓

## Testing Strategy

No code changes — verification is completeness review against acceptance criteria.

## Commit Plan

Single commit: analysis.md document (spike artifact, no code).
