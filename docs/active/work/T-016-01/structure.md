# T-016-01 Structure: Stripe Subscriptions

## Files to Create

### `lib/haul/billing.ex`
Billing behaviour + feature gate functions.

Public API:
- `create_customer(company)` — dispatches to adapter
- `create_subscription(customer_id, price_id)` — dispatches to adapter
- `cancel_subscription(subscription_id)` — dispatches to adapter
- `can?(company, feature)` — pure function, checks plan against feature matrix
- `plan_features(plan)` — returns list of features for a plan
- `plans()` — returns list of plan definitions (name, price, features)
- `price_id(plan)` — returns configured Stripe Price ID for a plan

Callbacks (behaviour):
- `create_customer/1`
- `create_subscription/2`
- `cancel_subscription/1`

### `lib/haul/billing/stripe.ex`
Production adapter. Implements `@behaviour Haul.Billing`.

- `create_customer/1` — `Stripe.Customer.create(%{email: ..., metadata: %{company_id: ...}})`
- `create_subscription/2` — `Stripe.Subscription.create(%{customer: id, items: [%{price: price_id}]})`
- `cancel_subscription/1` — `Stripe.Subscription.cancel(id)`

### `lib/haul/billing/sandbox.ex`
Dev/test adapter. Returns canned responses. Process notification for test assertions (same pattern as `Haul.Payments.Sandbox`).

### `lib/mix/tasks/haul/stripe_setup.ex`
Mix task `mix haul.stripe_setup`. Creates Stripe Products + Prices.

- Creates 3 products: Pro, Business, Dedicated (Starter is free, no Stripe product)
- Creates monthly prices for each
- Prints price IDs for env var config
- Idempotent: skips if products with matching metadata already exist

### `priv/repo/migrations/TIMESTAMP_add_subscription_billing_fields.exs`
Migration for Company table:
- Add `stripe_subscription_id :text` (nullable)
- Update `subscription_plan` default from `'free'` to `'starter'`
- Data migration: `UPDATE companies SET subscription_plan = 'starter' WHERE subscription_plan = 'free'`

## Files to Modify

### `lib/haul/accounts/company.ex`
- Change `subscription_plan` constraints from `[:free, :pro]` to `[:starter, :pro, :business, :dedicated]`
- Change default from `:free` to `:starter`
- Add `stripe_subscription_id` attribute (nullable string)
- Add `stripe_subscription_id` to `update_company` accept list

### `config/config.exs`
- Add `config :haul, :billing_adapter, Haul.Billing.Sandbox`
- Add empty Stripe price ID configs

### `config/runtime.exs`
- Add billing adapter selection (Stripe when STRIPE_SECRET_KEY is present)
- Add price ID env vars: `STRIPE_PRICE_PRO`, `STRIPE_PRICE_BUSINESS`, `STRIPE_PRICE_DEDICATED`

### `config/test.exs`
- Add `config :haul, :billing_adapter, Haul.Billing.Sandbox`

## Files to Create (Tests)

### `test/haul/billing_test.exs`
- Test `can?/2` for all plan/feature combinations
- Test `plan_features/1` returns correct features
- Test `plans/0` returns all plan definitions
- Test `create_customer/1` via sandbox adapter
- Test `create_subscription/2` via sandbox adapter
- Test `cancel_subscription/1` via sandbox adapter

### `test/mix/tasks/haul/stripe_setup_test.exs`
- Test task runs without error (with sandbox — won't actually call Stripe)
- Minimal: just verify the task module compiles and has expected function

## Module Boundaries

```
Haul.Billing (behaviour + pure functions)
├── Haul.Billing.Stripe (production adapter)
└── Haul.Billing.Sandbox (dev/test adapter)

Haul.Accounts.Company (resource — gains new attributes)

Mix.Tasks.Haul.StripeSetup (one-time setup task)
```

The Billing module does NOT depend on Accounts or any Ash resources. It receives a company struct (or map with `:subscription_plan`) and checks features. The adapter functions take primitive arguments (strings, maps), not Ash resources.

## Ordering

1. Migration (add columns, update data)
2. Company resource changes (new attributes, updated constraints)
3. Billing module + adapters
4. Config changes
5. Tests
6. Mix task (lowest priority — it's a one-time operational tool)
