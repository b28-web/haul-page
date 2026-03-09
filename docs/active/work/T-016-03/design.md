# T-016-03 Design: Billing Webhooks

## Decision: Separate Controller for Billing Webhooks

**Chosen approach:** New `BillingWebhookController` with dedicated route at `/webhooks/stripe/billing`.

**Why separate from existing WebhookController:**
- Ticket explicitly asks for `/webhooks/stripe/billing` endpoint
- Payment webhooks (Job payment intents) vs billing webhooks (subscriptions) are distinct domains
- Different webhook secrets allow Stripe endpoint-level separation
- Each controller stays focused — SRP

**Rejected: Extending existing WebhookController**
- Would mix payment and subscription concerns
- Single webhook secret for both — less flexible
- Controller already has its own set of event handlers

## Decision: Reuse Payments.verify_webhook_signature

The existing `Haul.Payments.verify_webhook_signature/3` works for any Stripe webhook. Use it with a separate billing webhook secret config key (`stripe_billing_webhook_secret`).

In dev/test, the sandbox adapter just does `Jason.decode` — no secret needed.

In production, operators configure a second Stripe webhook endpoint pointing at `/webhooks/stripe/billing` with its own signing secret.

## Decision: Company Lookup via stripe_customer_id

All billing webhook events carry a `customer` field. Lookup Company by `stripe_customer_id`.

Exception: `checkout.session.completed` — also has metadata. Use metadata `company_id` as primary (set during checkout creation in BillingLive), fall back to customer ID.

Need a `read` action or query on Company by `stripe_customer_id`. Add `:by_stripe_customer_id` read action.

## Decision: Price ID → Plan Reverse Mapping

Add `Haul.Billing.plan_for_price_id/1` that iterates configured price IDs and returns the matching plan atom. Returns `nil` for unknown price IDs.

## Decision: Dunning via dunning_started_at + Oban Cron

**Fields:** Add `dunning_started_at` (utc_datetime, nullable) to Company.

**Flow:**
1. `invoice.payment_failed` with `attempt_count >= 3` → set `dunning_started_at` to now
2. `invoice.payment_failed` with `attempt_count < 3` → log only (Stripe still retrying)
3. `invoice.paid` → clear `dunning_started_at` to nil
4. Oban cron job runs daily: finds companies where `dunning_started_at` is > 7 days ago → downgrade to `:starter`, clear dunning

**Why Oban cron over one-shot scheduled job:**
- More reliable — survives deploys
- Single check, not per-company timers
- Easy to reason about and test

**Warning banner:** BillingLive checks `company.dunning_started_at` — if set, shows warning.

## Decision: Email on Payment Failure

Simple approach: Build and deliver email inline in webhook handler (not Oban worker). Reason:
- Webhook is already async (called by Stripe)
- Single email, not bulk
- If delivery fails, it's not critical enough to retry via Oban
- Keeps it simple

Use `Haul.Mailer` with a new `Haul.Notifications.BillingEmail` module for the template.

## Decision: Idempotency

- `checkout.session.completed` → set plan + IDs. Replaying sets same values = safe.
- `subscription.updated` → set plan based on current price. Replaying = same result.
- `subscription.deleted` → set to `:starter`. Already starter = no-op.
- `invoice.payment_failed` → set `dunning_started_at` only if nil. Replaying = no-op.
- `invoice.paid` → clear `dunning_started_at`. Already nil = no-op.

No event deduplication table needed — operations are naturally idempotent.

## Decision: Logging

Use `Logger.info` for all successful event handling with Company ID.
Use `Logger.warning` for failures and missing data.
Format: `"Billing webhook: {event_type} for company #{company_id} — {action taken}"`

## Config Changes

- New key: `config :haul, :stripe_billing_webhook_secret, ""`
- Runtime.exs reads `STRIPE_BILLING_WEBHOOK_SECRET` env var
- Falls back to existing `STRIPE_WEBHOOK_SECRET` if billing-specific not set
