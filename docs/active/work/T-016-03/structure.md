# T-016-03 Structure: Billing Webhooks

## New Files

### `lib/haul_web/controllers/billing_webhook_controller.ex`
- Module: `HaulWeb.BillingWebhookController`
- Single action: `billing/2`
- Extracts raw body, verifies signature with billing webhook secret
- Pattern-matched `handle_event/1` clauses for each event type
- Private helpers: `find_company_by_customer/1`, `plan_from_subscription/1`

### `lib/haul/notifications/billing_email.ex`
- Module: `Haul.Notifications.BillingEmail`
- `payment_failed/1` — builds Swoosh email for operator warning
- Takes company struct, returns `Swoosh.Email.t()`

### `lib/haul/workers/check_dunning_grace.ex`
- Module: `Haul.Workers.CheckDunningGrace`
- Oban cron worker, runs daily
- Queries companies where `dunning_started_at` < 7 days ago
- Downgrades each to `:starter`, clears dunning fields

### `priv/repo/migrations/TIMESTAMP_add_dunning_started_at_to_companies.exs`
- Adds `dunning_started_at` (utc_datetime, nullable) to companies table

### `test/haul_web/controllers/billing_webhook_controller_test.exs`
- Tests for all 5 event types
- Idempotency tests
- Company state verification
- Unknown event handling

### `test/haul/workers/check_dunning_grace_test.exs`
- Tests grace period expiry logic
- Verifies downgrade happens after 7 days
- Verifies no downgrade within 7 days

## Modified Files

### `lib/haul/accounts/company.ex`
- Add `dunning_started_at` attribute (utc_datetime, nullable)
- Add `:by_stripe_customer_id` read action
- Add `dunning_started_at` to `:update_company` accept list

### `lib/haul/billing.ex`
- Add `plan_for_price_id/1` — reverse lookup price ID → plan atom

### `lib/haul_web/router.ex`
- Add route: `post "/stripe/billing", BillingWebhookController, :billing`
- In existing `/webhooks` scope

### `lib/haul_web/live/app/billing_live.ex`
- Add dunning warning banner in render when `current_company.dunning_started_at` is set
- Show days remaining in grace period

### `config/config.exs`
- Add `config :haul, :stripe_billing_webhook_secret, ""`

### `config/runtime.exs`
- Read `STRIPE_BILLING_WEBHOOK_SECRET` env var
- Fall back to `STRIPE_WEBHOOK_SECRET`

### `lib/haul/application.ex`
- Add Oban cron plugin config for `CheckDunningGrace` (daily schedule)

## Module Boundaries

```
BillingWebhookController
  ├── Haul.Payments.verify_webhook_signature/3  (signature check)
  ├── Haul.Accounts.Company  (Ash read/update)
  ├── Haul.Billing.plan_for_price_id/1  (price → plan mapping)
  ├── Haul.Notifications.BillingEmail  (email template)
  └── Haul.Mailer  (email delivery)

CheckDunningGrace (Oban cron)
  └── Haul.Accounts.Company  (query + update)
```

## Data Flow

1. Stripe → POST `/webhooks/stripe/billing` → BillingWebhookController
2. Controller verifies signature → parses event → dispatches to handler
3. Handler looks up Company by stripe_customer_id → updates plan/dunning state
4. For payment failures: also sends email via Mailer
5. Daily: CheckDunningGrace checks grace period expiry → downgrades
