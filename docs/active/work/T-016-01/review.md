# T-016-01 Review: Stripe Subscriptions

## Summary

Added subscription billing infrastructure: 4-tier plan model, Stripe Customer/Subscription linking, and feature gate module.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/billing.ex` | Billing behaviour, adapter dispatch, feature gates (`can?/2`), plan definitions |
| `lib/haul/billing/stripe.ex` | Production adapter — wraps Stripe Customer/Subscription APIs |
| `lib/haul/billing/sandbox.ex` | Dev/test adapter — canned responses with process notifications |
| `lib/mix/tasks/haul/stripe_setup.ex` | One-time Mix task to create Stripe Products/Prices |
| `priv/repo/migrations/20260309060000_add_subscription_billing_fields.exs` | Adds `stripe_subscription_id`, migrates `free→starter` |
| `test/haul/billing_test.exs` | 22 tests covering feature gates, plans, adapter dispatch |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/accounts/company.ex` | Plan enum: `[:free, :pro]` → `[:starter, :pro, :business, :dedicated]`, default `:starter`. Added `stripe_subscription_id` attribute. |
| `config/config.exs` | Added billing adapter + price ID configs |
| `config/runtime.exs` | Added billing adapter selection + price ID env vars in Stripe block |
| `config/test.exs` | Added billing sandbox adapter config |
| `test/haul/accounts/company_test.exs` | Updated assertion: `:free` → `:starter` |

## Acceptance Criteria Check

- [x] Stripe Products via Mix task (`mix haul.stripe_setup`) — Starter free (no Stripe product), Pro $29, Business $79, Dedicated $149
- [x] Company gains `subscription_plan` enum with `:starter, :pro, :business, :dedicated` (default `:starter`)
- [x] Company gains `stripe_customer_id` (already existed) and `stripe_subscription_id` (new)
- [x] Stripe Customer creation via `Haul.Billing.create_customer/1`
- [x] Feature gate: `Haul.Billing.can?(company, :sms_notifications)` checks plan
- [x] Feature gates: SMS (pro+), custom domain (pro+), payment collection (business+), crew app (business+)

## Test Coverage

- **22 new tests** in `test/haul/billing_test.exs`:
  - `can?/2`: 6 tests (all plans × positive/negative + edge cases)
  - `plan_features/1`: 5 tests (all plans + unknown)
  - `plans/0`: 6 tests (count, structure, price per plan)
  - Adapter functions: 3 tests (create_customer, create_subscription, cancel_subscription)
  - `price_id/1`: 2 tests
- **Existing test updated**: company_test.exs assertion `:free` → `:starter`
- **Full suite**: 382 tests, 0 new failures (4 pre-existing in SignupLiveTest — rate limiter)

## Open Concerns

1. **Pre-existing test failures**: 4 tests in `HaulWeb.App.SignupLiveTest` fail due to rate limiter blocking signup attempts during test. Not introduced by this ticket.

2. **Stripe API not tested end-to-end**: `Haul.Billing.Stripe` adapter wraps `stripity_stripe` but is not tested against real Stripe APIs (by design — production adapter testing requires live keys). The sandbox adapter provides test coverage for the dispatch layer.

3. **Mix task not integration-tested**: `mix haul.stripe_setup` calls live Stripe API and can only be tested with real keys. Module compilation is implicitly verified.

4. **No webhook handling yet**: Subscription lifecycle events (renewal, cancellation, payment failure) are handled by T-016-03. This ticket only sets up the data model and creation path.

5. **Feature gates not wired in yet**: `Haul.Billing.can?/2` exists but is not called anywhere yet. Downstream tickets (notifications, custom domains, payments) will integrate the gate checks.
