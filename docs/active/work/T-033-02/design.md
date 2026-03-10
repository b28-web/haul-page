# T-033-02 Design: Extract Pure Logic

## Problem

19 pure-logic tests are trapped in DataCase test files. The code is already well-separated — the issue is test organization, not code structure.

## Options considered

### Option A: Move tests to new unit test files

Create `*_unit_test.exs` companion files using `ExUnit.Case, async: true`. Remove the corresponding describe blocks from the DataCase files.

- Pros: Clean tier separation. No code changes to production modules. Test pyramid accurately reflects reality.
- Cons: Introduces new test files. "Unit" suffix is a naming convention we'd need to maintain.

### Option B: Split within the same file using conditional use

Use `ExUnit.Case` for the pure tests and `DataCase` for the DB tests within the same file.

- Pros: No new files.
- Cons: ExUnit doesn't support mixing `use` declarations in a single module. Would need nested modules, which is ugly and non-standard.

### Option C: New source modules + test files

Extract pure functions into new modules (e.g., `Haul.Onboarding.Slug`) with dedicated test files.

- Pros: Strong module boundaries.
- Cons: Over-engineering. The functions are 3-5 lines each, already public. Creating modules for `derive_slug` alone violates the "don't over-abstract" rule.

### Option D: Do nothing for cost_tracker (already async)

The cost_tracker tests are already `async: true`. Skip them and only extract onboarding + seeder.

- Pros: Less work.
- Cons: Doesn't fix the tier classification. DataCase with async:true still starts the sandbox unnecessarily.

## Decision: Option A

Move pure tests to `*_unit_test.exs` companion files. This is the standard pattern for this codebase (test files named by module, organized by tier).

**Naming:** `onboarding_unit_test.exs` and `cost_tracker_unit_test.exs`. The `_unit` suffix distinguishes them from the DataCase files and makes tier clear.

**Seeder:** Don't create a new file. The 2 `parse_frontmatter!` tests in seeder_test.exs delegate to `Content.Markdown` which already has 5 unit tests in `markdown_test.exs`. Remove the 2 duplicate tests from seeder_test.

## Coverage accounting

| Source | Tests removed from DataCase | Tests added to ExUnit.Case | Net |
|--------|---------------------------|---------------------------|-----|
| onboarding_test.exs | 5 (derive_slug 4, site_url 1) | 5 → onboarding_unit_test.exs | 0 |
| cost_tracker_test.exs | 10 (estimate_tokens 3, estimate_cost 3, model_for_function 3, pricing 1) | 10 → cost_tracker_unit_test.exs | 0 |
| seeder_test.exs | 2 (parse_frontmatter!) | 0 (already covered by markdown_test.exs: 5 tests) | -2 (dedup, +3 net coverage) |

**Total: 17 tests moved/removed from DataCase, 15 added as unit tests, 0 net loss in assertion coverage.**

## Non-goals

- No production code changes
- No changes to AI modules (EditApplier, Provisioner) — the audit marked those as MOCK targets for T-033-03, not extraction targets
- No worker module changes — those are MOCK targets for T-033-03
