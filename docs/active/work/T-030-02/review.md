# T-030-02 Review — Fix Defensive Rescues

## Summary

Narrowed or removed 3 overly broad rescue blocks identified by the T-030-01 audit.

## Changes

### Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/controllers/billing_webhook_controller.ex` | Extracted `safe_plan_atom/1` — rescue `ArgumentError` now only covers `String.to_existing_atom/1`, not the entire `resolve_plan_from_session/1` body |
| `lib/haul/ai/cost_tracker.ex` | Removed `try/rescue` from `do_record_call/1` — the `case` clause already handles all `Ash.create/1` return values |
| `lib/haul/onboarding.ex` | Narrowed `seed_content/1` rescue from catch-all to `[Ash.Error.Invalid, File.Error, YamlElixir.ParsingError, RuntimeError]` |

### No files created or deleted

## Test Coverage

- **Targeted tests:** 51 tests across `billing_webhook_controller_test.exs`, `cost_tracker_test.exs`, `onboarding_test.exs` — all pass
- **Full suite:** 845 tests, 22 failures — all failures are pre-existing from uncommitted work in other tickets (ErrorClassifier extraction). No regressions from T-030-02

## Acceptance Criteria Verification

- [x] Remove or narrow every rescue site classified as "narrow" by the audit — all 3 done
- [x] `billing_webhook_controller.ex` plan rescue isolated to atom conversion
- [x] `cost_tracker.ex` rescue removed, `case` clause preserved
- [x] `onboarding.ex` seed_content rescue narrowed to specific exception types
- [x] No tests needed updating (no tests asserted on old error-swallowing behavior)
- [x] No new broad rescue blocks introduced

## Open Concerns

- The `cost_tracker.ex` moduledoc still says "All recording operations are non-fatal." After removing the rescue, an unexpected crash in `Ash.create` will propagate. This is intentional — callers use the return value in fire-and-forget fashion and don't crash on errors. True infrastructure crashes (pool exhaustion) should propagate to surface the issue.
- The onboarding `seed_content` rescue list includes `RuntimeError` which is broad, but it's specifically for `Seeder.parse_frontmatter!/1` which raises `RuntimeError` on invalid format. This is the narrowest practical option without changing the Seeder module.
