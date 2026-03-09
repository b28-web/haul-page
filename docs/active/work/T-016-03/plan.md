# T-016-03 Plan: Billing Webhooks

## Step 1: Migration — Add dunning_started_at to companies

- Generate migration: `add_dunning_started_at_to_companies`
- Add `dunning_started_at` column (utc_datetime, nullable)
- Run migration
- **Verify:** `mix ecto.migrate` succeeds

## Step 2: Update Company resource

- Add `dunning_started_at` attribute (utc_datetime, nullable)
- Add `:by_stripe_customer_id` read action with `get_by [:stripe_customer_id]`
- Add `dunning_started_at` to `:update_company` accept list
- **Verify:** existing tests still pass

## Step 3: Add plan_for_price_id to Billing module

- Add `plan_for_price_id/1` function
- Iterates [:pro, :business, :dedicated], compares `price_id(plan)` to input
- Returns matching plan atom or nil
- **Verify:** unit test in billing_test.exs

## Step 4: BillingWebhookController

- Create `lib/haul_web/controllers/billing_webhook_controller.ex`
- Action: `billing/2` — same pattern as existing webhook controller
- Uses `stripe_billing_webhook_secret` config
- Event handlers:
  - `checkout.session.completed` → find company (metadata or customer), set plan + IDs
  - `customer.subscription.updated` → find company by customer, update plan
  - `customer.subscription.deleted` → find company by customer, downgrade to starter
  - `invoice.payment_failed` → find company, set dunning if final attempt, send email
  - `invoice.paid` → find company, clear dunning
  - Unknown → log debug, return ok
- **Verify:** controller compiles

## Step 5: Config + Router

- Add `stripe_billing_webhook_secret` to config.exs
- Add runtime.exs env var reading with fallback
- Add route in router.ex: `post "/stripe/billing", BillingWebhookController, :billing`
- **Verify:** `mix compile` clean, route exists

## Step 6: BillingEmail notification

- Create `lib/haul/notifications/billing_email.ex`
- `payment_failed/1` — builds warning email to operator
- Subject: "Payment failed — action needed"
- Body: company name, what happened, what to expect
- **Verify:** module compiles

## Step 7: Dunning grace Oban worker

- Create `lib/haul/workers/check_dunning_grace.ex`
- Oban Worker on `:default` queue
- `perform/1`: query companies with `dunning_started_at` older than 7 days
- Downgrade each to `:starter`, clear `dunning_started_at` and `stripe_subscription_id`
- Add cron config to application.ex Oban config
- **Verify:** module compiles

## Step 8: BillingLive dunning banner

- In BillingLive render, add conditional warning banner
- Show when `current_company.dunning_started_at` is not nil
- Display: "Payment issue — your plan will downgrade in X days"
- **Verify:** visual check

## Step 9: Controller tests

- Create `test/haul_web/controllers/billing_webhook_controller_test.exs`
- Setup: create Company with stripe_customer_id + stripe_subscription_id
- Tests:
  - checkout.session.completed sets plan and IDs
  - subscription.updated changes plan
  - subscription.deleted downgrades to starter
  - invoice.payment_failed sets dunning_started_at
  - invoice.paid clears dunning_started_at
  - Idempotency for each event type
  - Unknown event returns 200
  - Invalid payload returns 400
- **Verify:** all tests pass

## Step 10: Dunning worker tests

- Create `test/haul/workers/check_dunning_grace_test.exs`
- Test: company past grace period gets downgraded
- Test: company within grace period is not downgraded
- Test: company without dunning is untouched
- **Verify:** all tests pass

## Testing Strategy

- Unit tests: `plan_for_price_id`, billing email, feature gates
- Integration tests: webhook controller (full HTTP round-trip via ConnCase)
- Worker tests: dunning grace period logic (Oban testing)
- All use sandbox adapter — no real Stripe calls
- Run `mix test` — all 258+ tests pass
