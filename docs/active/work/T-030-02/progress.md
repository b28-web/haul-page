# T-030-02 Progress — Fix Defensive Rescues

## Completed

### Step 1: Fix billing webhook controller rescue
- Extracted `safe_plan_atom/1` helper
- `resolve_plan_from_session/1` no longer has function-level rescue
- 18 billing webhook tests pass

### Step 2: Fix cost tracker rescue
- Removed `try/rescue` block from `do_record_call/1`
- Kept `case` clause for `Ash.create/1` return values
- Cost tracker tests pass

### Step 3: Fix onboarding seed_content rescue
- Removed `try` wrapper
- Narrowed rescue to `[Ash.Error.Invalid, File.Error, YamlElixir.ParsingError, RuntimeError]`
- 7 onboarding tests pass

### Step 4: Full test suite
- 51 targeted tests: 0 failures
- Full suite: 22 failures, all pre-existing (from uncommitted ErrorClassifier extraction in other ticket work)
- No regressions from T-030-02 changes

## Remaining

None — all steps complete.
