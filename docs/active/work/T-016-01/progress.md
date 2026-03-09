# T-016-01 Progress: Stripe Subscriptions

## Completed

1. **Migration** — `20260309060000_add_subscription_billing_fields.exs` created and run successfully. Adds `stripe_subscription_id`, migrates `free` → `starter`, updates default.

2. **Company resource updated** — `subscription_plan` constraint now `[:starter, :pro, :business, :dedicated]`, default `:starter`. New `stripe_subscription_id` attribute added. `update_company` accepts both new fields.

3. **Billing module** — `Haul.Billing` created with:
   - Adapter-dispatched: `create_customer/1`, `create_subscription/2`, `cancel_subscription/1`
   - Pure functions: `can?/2`, `plan_features/1`, `plans/0`, `price_id/1`

4. **Billing adapters** — `Haul.Billing.Stripe` (production) and `Haul.Billing.Sandbox` (dev/test) created following established adapter pattern.

5. **Mix task** — `mix haul.stripe_setup` created for one-time Stripe Product/Price creation.

6. **Config** — billing adapter + price ID configs added to `config.exs`, `runtime.exs`, `test.exs`.

7. **Tests** — 22 new tests in `test/haul/billing_test.exs` covering feature gates, plan definitions, adapter dispatch. Existing company test updated (`free` → `starter`).

8. **Full suite** — 382 tests total. 4 pre-existing failures in SignupLiveTest (rate limiter issue, unrelated).

## No Deviations

Implementation followed the plan exactly.
