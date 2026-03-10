# T-030-02 Structure — Fix Defensive Rescues

## Files Modified

### 1. `lib/haul_web/controllers/billing_webhook_controller.ex`
- Extract `safe_plan_atom/1` private function (rescue `ArgumentError` only on atom conversion)
- Modify `resolve_plan_from_session/1` to call `safe_plan_atom/1` instead of having a function-level rescue

### 2. `lib/haul/ai/cost_tracker.ex`
- Remove `try/rescue` block from `do_record_call/1`
- Keep the `case` clause as-is — it already handles all `Ash.create/1` return values

### 3. `lib/haul/onboarding.ex`
- Remove `try` wrapper from `seed_content/1`
- Narrow `rescue` to specific exception types: `Ash.Error.Invalid`, `File.Error`, `YamlElixir.ParsingError`, `RuntimeError`

## Files Not Modified

- No test files need updating — audit confirmed no tests assert on the old error-swallowing behavior for these three sites
- No caller changes needed — all three changes preserve the same return value contract

## Module Boundaries

No new modules. No interface changes. All modifications are internal to private functions.

## Ordering

Changes are independent — no ordering constraints. Can be done in any sequence.
