# T-030-01 Review: Audit Error Handling

## Summary

Research-only ticket. No code changes. Produced `audit.md` cataloging all 14 error handling sites in `lib/`.

## Files Created

| File | Purpose |
|------|---------|
| `docs/active/work/T-030-01/audit.md` | Full error handling catalog with classifications |
| `docs/active/work/T-030-01/research.md` | Raw findings from codebase search |
| `docs/active/work/T-030-01/design.md` | Classification framework and decisions |
| `docs/active/work/T-030-01/structure.md` | Deliverable structure |
| `docs/active/work/T-030-01/plan.md` | Implementation steps |
| `docs/active/work/T-030-01/progress.md` | Execution tracking |

## Acceptance Criteria Verification

- [x] `audit.md` catalogs every error handling site in `lib/`
  - 8 `try/rescue` and `rescue` blocks
  - 4 workers that return `:ok` on failure
  - 1 function returning `{:ok, []}` on API failure (Google Places)
  - 1 `with` catch-all else clause (require_auth plug)
- [x] Each site classified as Remove, Narrow, Keep, or Fix return
  - 7 Keep, 3 Narrow, 4 Fix return, 0 Remove
- [x] "Remove" and "narrow" sites include caller expectations and test coverage notes
- [x] No code changes made

## Key Findings

1. **No sites classified as "remove"** — the codebase doesn't have pure defensive rescues hiding bugs. All rescues serve a purpose (boundary code, adapter conversion, or fire-and-forget notifications).

2. **3 sites need narrowing** — rescues that are valid but catch too broadly: billing plan resolution, cost tracker, and onboarding seeder. These could mask unrelated bugs.

3. **4 workers need return value fixes** — email, SMS, cert removal, and conversation cleanup workers all return `:ok` when they should propagate errors, preventing Oban retries on transient failures.

4. **Test coverage of error paths is sparse** — most worker tests only cover happy paths. The "fix return" changes in T-030-03 will need new error-path tests.

## Test Coverage

No tests to run — research-only ticket.

## Open Concerns

1. **Seeder API**: The `onboarding.ex` rescue wraps `Seeder.seed!/1`. If a non-bang `seed/2` exists or can be added, the rescue becomes unnecessary. T-030-02 should check.

2. **Cost tracker design tension**: The module docstring says "all recording operations are non-fatal." Narrowing the rescue is safe, but removing it entirely could let unexpected DB errors crash AI operations. T-030-02 should evaluate carefully.

3. **Notification worker delivery failures**: Sites #9 and #10 (email/SMS workers) also ignore `Mailer.deliver()` and `SMS.send_sms()` return values. The audit focused on `Ash.get` failures, but delivery failures are also silently swallowed. T-030-03 may want to address this too.

## Downstream Impact

- **T-030-02** has 3 sites to fix (narrow rescues)
- **T-030-03** has 4 sites to fix (worker returns) plus potentially 2 more (delivery return values)
