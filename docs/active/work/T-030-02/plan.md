# T-030-02 Plan — Fix Defensive Rescues

## Steps

### Step 1: Fix billing webhook controller rescue
- Extract `safe_plan_atom/1` from `resolve_plan_from_session/1`
- Remove function-level `rescue ArgumentError` from `resolve_plan_from_session/1`
- Run: `mix test test/haul_web/controllers/billing_webhook_controller_test.exs`

### Step 2: Fix cost tracker rescue
- Remove `try/rescue` from `do_record_call/1`, keep `case` clause
- Run: `mix test test/haul/ai/cost_tracker_test.exs`

### Step 3: Fix onboarding seed_content rescue
- Remove `try` wrapper, narrow `rescue` to specific exception types
- Run: `mix test test/haul/onboarding_test.exs`

### Step 4: Full test suite
- Run `mix test` to verify all 845+ tests pass
- Verify no new broad rescue blocks introduced

## Verification

- Each step has a targeted test run
- Final full suite confirms no regressions
- `grep -r "rescue" lib/ | grep -v "#"` confirms no new broad rescues
