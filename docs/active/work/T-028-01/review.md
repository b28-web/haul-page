# T-028-01 Review: Logic Audit

## Summary

Research-only ticket. No code changes — produced `audit.md` cataloging extractable pure functions across the codebase.

## Files Created

| File | Purpose |
|------|---------|
| `docs/active/work/T-028-01/research.md` | Codebase survey of all candidate areas |
| `docs/active/work/T-028-01/design.md` | Audit structure and categorization decisions |
| `docs/active/work/T-028-01/structure.md` | Document format and entry template |
| `docs/active/work/T-028-01/plan.md` | Execution steps |
| `docs/active/work/T-028-01/progress.md` | Completion tracking |
| `docs/active/work/T-028-01/audit.md` | **Primary deliverable** — full audit catalog |

## Files Modified

None. This is a pure research ticket.

## Acceptance Criteria Checklist

- [x] `audit.md` cataloging extractable pure functions across Ash resources, LiveViews, controllers, workers
- [x] Each candidate documented with: source file/function, description, test coverage, extraction difficulty, dependencies
- [x] Categorized into Pure / DB-read / Tightly-coupled
- [x] Prioritized by test migration potential and code clarity
- [x] ≥20 extractable functions identified: **56 found**
- [x] ≥10 pure category: **38 found**

## Test Coverage

No code changes, no tests needed. Verified line numbers against source files for accuracy.

## Key Findings

1. **56 extractable candidates** found (38 pure, 3 DB-read, 4 tightly coupled, plus 11 already well-extracted)
2. **4 duplication patterns**: `get_field/2` (×4), `friendly_error/1` (×3), `transient?/1` (×2), `format_price/1` (×2)
3. **Billing feature gates** (`can?/2`, `plan_features/1`) are the highest-impact extraction — zero unit tests, used in signup/billing flows
4. **Notification templates** (BookingEmail) are already pure but lack isolated unit tests
5. **All top 20 candidates are pure** — no "DB-read" extractions in the high-priority list

## Open Concerns

- **Slug derivation duplication**: `Onboarding.derive_slug/1` and `Company.create_company` action both derive slugs. Need to decide canonical location during T-028-02.
- **MDEx render duplication**: Page resource has identical MDEx calls in `draft` and `edit` actions. Extraction requires modifying Ash action DSL which may be moderate difficulty.
- **`get_field/2` scope**: 4 copies suggests a missing shared helper. Could go in `HaulWeb.Helpers` but the function is trivial — dedup value is mostly about convention.

## Downstream Work

- **T-028-02** (extract billing/content logic): Items 1–29 and 49–56 from the audit
- **T-028-03** (extract LiveView logic): Items 30–48 from the audit
