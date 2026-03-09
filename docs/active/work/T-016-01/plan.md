# T-016-01 Plan: Stripe Subscriptions

## Step 1: Migration — Add billing fields to Company

Create `priv/repo/migrations/TIMESTAMP_add_subscription_billing_fields.exs`:
- Add `stripe_subscription_id` column (text, nullable)
- Change `subscription_plan` default from `'free'` to `'starter'`
- Data migration: `UPDATE companies SET subscription_plan = 'starter' WHERE subscription_plan = 'free'`

**Verify:** `mix ecto.migrate` succeeds. Rollback works.

## Step 2: Update Company resource

Modify `lib/haul/accounts/company.ex`:
- Change `subscription_plan` constraint from `[:free, :pro]` to `[:starter, :pro, :business, :dedicated]`
- Change default from `:free` to `:starter`
- Add `stripe_subscription_id` attribute (nullable string, public)
- Add `stripe_subscription_id` to `update_company` accept list

**Verify:** Existing tests still pass (they may create companies with default plan).

## Step 3: Billing module with feature gates

Create `lib/haul/billing.ex`:
- Define `@behaviour` callbacks: `create_customer/1`, `create_subscription/2`, `cancel_subscription/1`
- Implement dispatcher functions that delegate to configured adapter
- Implement `can?/2` pure function with feature matrix
- Implement `plan_features/1`, `plans/0`, `price_id/1`

**Verify:** Module compiles. Feature gate logic is correct by unit test.

## Step 4: Billing adapters

Create `lib/haul/billing/stripe.ex`:
- Implement `create_customer/1` wrapping `Stripe.Customer.create/1`
- Implement `create_subscription/2` wrapping `Stripe.Subscription.create/1`
- Implement `cancel_subscription/1` wrapping `Stripe.Subscription.cancel/2`

Create `lib/haul/billing/sandbox.ex`:
- Return canned responses for all callbacks
- Use process notification pattern for test assertions

**Verify:** Both adapters compile. Sandbox returns expected shapes.

## Step 5: Config changes

Modify `config/config.exs`:
- Add `config :haul, :billing_adapter, Haul.Billing.Sandbox`
- Add `config :haul, :stripe_price_pro, ""`
- Add `config :haul, :stripe_price_business, ""`
- Add `config :haul, :stripe_price_dedicated, ""`

Modify `config/runtime.exs`:
- In Stripe config block: add billing adapter selection
- Add price ID env vars

Modify `config/test.exs`:
- Add `config :haul, :billing_adapter, Haul.Billing.Sandbox`

**Verify:** Config compiles. `Application.get_env(:haul, :billing_adapter)` returns Sandbox in test.

## Step 6: Tests

Create `test/haul/billing_test.exs`:
- Test `can?/2` for each plan × feature combination (positive and negative)
- Test `plan_features/1` for all 4 plans
- Test `plans/0` returns 4 plans with correct structure
- Test `create_customer/1` returns `{:ok, customer_id}`
- Test `create_subscription/2` returns `{:ok, subscription_map}`
- Test `cancel_subscription/1` returns `{:ok, subscription_map}`
- Test `price_id/1` for each paid plan

**Verify:** All new tests pass. All existing tests pass.

## Step 7: Mix task for Stripe product setup

Create `lib/mix/tasks/haul/stripe_setup.ex`:
- `mix haul.stripe_setup` creates Products + Prices via Stripe API
- Prints created IDs
- Idempotent via metadata-based lookup

Create `test/mix/tasks/haul/stripe_setup_test.exs`:
- Verify module compiles and task function exists

**Verify:** Task compiles. Test passes.

## Step 8: Run full test suite

Run `mix test` to ensure nothing is broken.

**Verify:** All tests pass, including new billing tests.

## Testing Strategy

- **Unit tests:** `can?/2` feature matrix (exhaustive), plan definitions, adapter responses
- **No integration tests needed:** This ticket doesn't touch LiveView or controllers
- **Existing test impact:** Companies created in tests use default plan — changing default from `:free` to `:starter` may need updates in test helpers or fixtures
