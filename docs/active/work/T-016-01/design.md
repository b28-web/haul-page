# T-016-01 Design: Stripe Subscriptions

## Decision Summary

1. **New `Haul.Billing` module** with adapter pattern (like Payments)
2. **Extend Company resource** with `stripe_subscription_id` and updated plan enum
3. **Mix task `mix haul.stripe_setup`** for creating Stripe Products/Prices
4. **Feature gate as pure function** — no GenServer, no DB lookup, just pattern matching on plan atom

## Approach: Billing Adapter Pattern

### Option A: Extend Haul.Payments with subscription methods
- Pro: Single adapter interface
- Con: Payments is about one-time charges; subscriptions are a different domain. Mixes concerns.

### Option B: New Haul.Billing behaviour + adapter ✓
- Pro: Clean separation. Payments = one-time charges. Billing = subscriptions + feature gates.
- Pro: Can test subscription logic independently
- Pro: Follows established pattern (Payments already did this)
- Con: One more adapter pair to maintain

**Decision: Option B.** The Billing module owns subscription lifecycle. The Payments module stays focused on one-time payment intents.

## Billing Module Design

### `Haul.Billing` (behaviour + dispatch)
```
Callbacks:
- create_customer(company) → {:ok, customer_id} | {:error, term}
- create_subscription(customer_id, price_id) → {:ok, subscription_map} | {:error, term}
- cancel_subscription(subscription_id) → {:ok, subscription_map} | {:error, term}
```

Plus pure functions (not adapter-dispatched):
- `can?(company, feature)` — pattern match on plan, returns boolean
- `plan_features(plan)` → list of features for the plan
- `plans()` → list of plan definitions with names, prices, features

### `Haul.Billing.Stripe` (production adapter)
Wraps `Stripe.Customer.create/1`, `Stripe.Subscription.create/1`, `Stripe.Subscription.cancel/2`.

### `Haul.Billing.Sandbox` (dev/test adapter)
Returns canned responses. Same process notification pattern as Payments.Sandbox.

## Feature Gate Design

### Option A: Database-backed feature flags
- Pro: Runtime toggleable
- Con: Over-engineered for 4 static plans. Adds DB queries on every check.

### Option B: Pure function with compile-time feature matrix ✓
- Pro: Zero runtime cost, trivially testable, no DB dependency
- Pro: Feature matrix is clear and auditable in one place
- Con: Requires code deploy to change plan features (acceptable — plan changes are rare)

**Decision: Option B.** `Haul.Billing.can?/2` is a pure function. The company struct carries `subscription_plan`, so no DB lookup needed at check time.

Feature matrix:
```
:starter  → []
:pro      → [:sms_notifications, :custom_domain]
:business → [:sms_notifications, :custom_domain, :payment_collection, :crew_app]
:dedicated → [:sms_notifications, :custom_domain, :payment_collection, :crew_app]
```

Higher plans inherit all lower plan features. Implementation: check if feature is in `plan_features(plan)`.

## Plan Enum Migration

### Option A: Add new values, keep :free
- Pro: No data migration
- Con: Inconsistent naming (`:free` vs `:starter`)

### Option B: Rename :free → :starter, add :business/:dedicated ✓
- Pro: Clean, matches AC exactly
- Con: Requires data migration for existing rows

**Decision: Option B.** Single migration: add column default change, UPDATE existing rows, add new constraint.

Since Ash stores atoms as text in Postgres, the migration does:
1. `UPDATE companies SET subscription_plan = 'starter' WHERE subscription_plan = 'free'`
2. Add `stripe_subscription_id` column
3. Alter default from `'free'` to `'starter'`

## Mix Task Design

`mix haul.stripe_setup` — creates Stripe Products and Prices via API.

- Idempotent: checks if products exist by metadata lookup before creating
- Prints product/price IDs for env var configuration
- Only runs against live Stripe API (not sandbox)
- Stores price IDs as module attributes in `Haul.Billing` for reference

Price IDs will be configured via env vars (`STRIPE_PRICE_PRO`, `STRIPE_PRICE_BUSINESS`, `STRIPE_PRICE_DEDICATED`) since they differ per Stripe account.

## What Was Rejected

- **Ash resource for Plans/Subscriptions** — unnecessary complexity. Plans are static, not user-editable data. A module with constants is sufficient.
- **Webhook handling in this ticket** — T-016-03 handles subscription webhooks. This ticket only sets up the data model and feature gates.
- **LiveView upgrade flow** — T-016-02 handles the UI. This ticket is backend-only.
- **GenServer for feature caching** — plans are on the Company struct, already in memory during requests. No caching needed.
