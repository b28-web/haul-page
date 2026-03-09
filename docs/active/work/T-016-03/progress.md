# T-016-03 Progress: Billing Webhooks

## Completed Steps

### Step 1: Migration ✓
- Created `priv/repo/migrations/20260309070100_add_dunning_started_at_to_companies.exs`
- Adds `dunning_started_at` (utc_datetime, nullable) to companies table
- Migration ran successfully (timestamp adjusted from 070000 to 070100 to avoid conflict with domain_status migration from another agent)

### Step 2: Company resource ✓
- Added `dunning_started_at` attribute to Company
- Added `:by_stripe_customer_id` read action with argument-based filter
- Added `dunning_started_at` to `:update_company` accept list

### Step 3: plan_for_price_id ✓
- Added `plan_for_price_id/1` to `Haul.Billing`
- Reverse lookup: iterates [:pro, :business, :dedicated] and matches against configured price IDs
- Returns nil for unknown or non-string input
- Added 3 unit tests

### Step 4: BillingWebhookController ✓
- Created `lib/haul_web/controllers/billing_webhook_controller.ex`
- Handles all 5 required event types + unknown events
- Company lookup via `stripe_customer_id` (or metadata `company_id` for checkout)
- Plan resolution from subscription items or checkout metadata
- Dunning logic: sets `dunning_started_at` after 3 failed attempts
- Sends payment failure email via BillingEmail + Mailer
- All operations logged with Company ID

### Step 5: Config + Router ✓
- Added `stripe_billing_webhook_secret` to config.exs
- Added runtime.exs reading of `STRIPE_BILLING_WEBHOOK_SECRET` with fallback to `STRIPE_WEBHOOK_SECRET`
- Added route: `post "/stripe/billing", BillingWebhookController, :billing`

### Step 6: BillingEmail ✓
- Created `lib/haul/notifications/billing_email.ex`
- `payment_failed/1` builds warning email to operator
- Uses Swoosh.Email, operator config for from address

### Step 7: Dunning grace Oban worker ✓
- Created `lib/haul/workers/check_dunning_grace.ex`
- Queries companies with expired grace period (dunning_started_at > 7 days ago)
- Downgrades to :starter, clears dunning and subscription ID
- Added cron config to Oban: runs daily at 6 AM UTC
- Added :default queue (capacity 5) to Oban config

### Step 8: BillingLive dunning banner ✓
- Added conditional warning banner showing when `dunning_started_at` is set
- Yellow warning theme with exclamation icon
- Shows days remaining until downgrade

### Step 9: Controller tests ✓
- 14 tests covering all event types, idempotency, edge cases
- Tests: checkout sets plan/IDs, subscription update changes plan, deletion downgrades, payment failure sets dunning, invoice paid clears dunning, unknown events, invalid payload

### Step 10: Dunning worker tests ✓
- 3 tests: past grace → downgrade, within grace → no change, no dunning → no change

## Test Results

466 tests, 0 failures (up from 258 pre-existing + new tests from other agents)

## Deviations from Plan

- Migration timestamp changed from 070000 to 070100 due to conflict with another agent's migration
- Used `Ash.Query.for_read` + `Ash.read_one` for Company lookup instead of `Ash.run_action` (correct Ash API for read actions with arguments)
- Required `Ash.Query` in dunning worker for filter macro support
