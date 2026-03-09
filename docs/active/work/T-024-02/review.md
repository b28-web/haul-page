# T-024-02 Review: Timing Analysis

## Summary of Changes

### Files Created
- **docs/active/work/T-024-02/analysis.md** — Primary deliverable. Diagnostic report covering all acceptance criteria: top 10 slowest files, async audit, setup cost analysis, compilation breakdown, bottleneck categorization, prioritized fix list, and projected runtimes.
- **docs/active/work/T-024-02/research.md** — Raw timing data and codebase exploration findings
- **docs/active/work/T-024-02/design.md** — Analysis framework and categorization approach
- **docs/active/work/T-024-02/structure.md** — Document structure specification
- **docs/active/work/T-024-02/plan.md** — Step-by-step execution plan
- **docs/active/work/T-024-02/progress.md** — Implementation tracking

### Files Modified
None. This is a spike — analysis only, no code changes.

## Acceptance Criteria Verification

| Criterion | Status | Location in analysis.md |
|-----------|--------|------------------------|
| Run `HAUL_TEST_TIMING=1 mix test` and capture report | Done | JSON at test/reports/timing.json |
| Top 10 slowest files with per-test breakdown | Done | "Top 10 Slowest Files" section |
| Async audit: every async:false file with justification | Done | "Async Audit" section — 55 sync files catalogued |
| Setup cost: expensive setup/setup_all blocks | Done | "Setup Cost Audit" section |
| Compilation vs execution breakdown | Done | "Compilation vs Execution" section |
| Categorize bottlenecks (inherently slow / fixable / async / sleeps) | Done | "Bottleneck Categories" section |
| Prioritized list of fixes with estimated savings | Done | "Prioritized Fix List" — 4 tiers |
| Projected runtime after fixes | Done | "Projected Runtime After Fixes" table |

## Key Findings for T-024-03

1. **Tier 1 (setup deduplication) is the highest-leverage fix.** Moving `create_authenticated_context()` from per-test `setup` to `setup_all` in 14 files should save 35-40s (~22% of total runtime). This is mechanical refactoring with low risk.

2. **Chat sleep reduction is Tier 2.** Making extraction debounce configurable (800ms → 50ms in test) would save 10-15s. Requires a small production code change.

3. **Async conversion has negligible impact.** Only 5 files (330ms total) could potentially be converted. Not worth the effort.

4. **Target runtime: 95-110s after Tier 1, 75-90s after Tier 1+2.** Getting below 2 minutes is achievable with Tier 1 alone.

## Test Coverage

No code changes, so no test impact. Existing suite: 746 tests, 0 failures.

## Open Concerns

1. **`setup_all` changes require careful test isolation.** Tests that mutate shared tenant state (create/delete records) may need unique names or per-test cleanup to avoid interference. Most admin CRUD tests already use unique names, but this needs verification per-file during T-024-03.

2. **Ecto sandbox mode for `setup_all`.** When setup runs in `setup_all`, the sandbox connection is not automatically shared with individual tests. T-024-03 will need to use `Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, {:shared, self()})` in `setup_all` and ensure cleanup happens correctly.

3. **CostTracker ownership warning.** During the timing run, `Haul.AI.ContentGeneratorTest` produced `DBConnection.OwnershipError` warnings from CostTracker trying to write to DB from an unowned process. This is a pre-existing issue (tests pass despite it) but should be addressed separately.

4. **bcrypt rounds in test.** Not verified whether bcrypt is already configured with reduced rounds for test env. If not, reducing from default 12 to 4 rounds would save ~20ms per user registration (200+ registrations across sync tests = ~4s).
