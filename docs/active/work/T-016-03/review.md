# T-016-03 Review: Billing Webhooks

## Summary

Implemented the billing webhook endpoint at `/webhooks/stripe/billing` to keep subscription state in sync with Stripe. All five required event types are handled, with dunning flow, idempotency, and audit logging.

## Files Created

| File | Purpose |
|---|---|
| `lib/haul_web/controllers/billing_webhook_controller.ex` | Webhook endpoint — handles 5 Stripe event types |
| `lib/haul/notifications/billing_email.ex` | Payment failure email template |
| `lib/haul/workers/check_dunning_grace.ex` | Oban cron worker — downgrades after 7-day grace |
| `priv/repo/migrations/20260309070100_add_dunning_started_at_to_companies.exs` | Adds dunning timestamp to companies |
| `test/haul_web/controllers/billing_webhook_controller_test.exs` | 14 controller tests |
| `test/haul/workers/check_dunning_grace_test.exs` | 3 dunning worker tests |

## Files Modified

| File | Change |
|---|---|
| `lib/haul/accounts/company.ex` | Added `dunning_started_at` attribute, `:by_stripe_customer_id` read action |
| `lib/haul/billing.ex` | Added `plan_for_price_id/1` reverse lookup |
| `lib/haul_web/router.ex` | Added `/webhooks/stripe/billing` route |
| `lib/haul_web/live/app/billing_live.ex` | Added dunning warning banner + `days_until_downgrade/1` |
| `config/config.exs` | Added `stripe_billing_webhook_secret`, Oban cron config, :default queue |
| `config/runtime.exs` | Added `STRIPE_BILLING_WEBHOOK_SECRET` env var reading |
| `test/haul/billing_test.exs` | Added 3 tests for `plan_for_price_id/1` |

## Test Coverage

- **Webhook controller tests (14):** All 5 event types tested with state verification. Idempotency tests for checkout, deletion, and dunning. Edge cases: unknown events (200 OK), unknown customer (200 OK), invalid payload (400).
- **Dunning worker tests (3):** Past grace → downgrade, within grace → no change, no dunning → no change.
- **Billing unit tests (3 new):** `plan_for_price_id` maps test price IDs correctly, returns nil for unknowns and non-strings.
- **Total: 466 tests, 0 failures**

## Acceptance Criteria Checklist

- [x] `/webhooks/stripe/billing` endpoint (separate from customer-payment webhooks)
- [x] Webhook signature verification (uses `stripe_billing_webhook_secret`)
- [x] `checkout.session.completed` → set plan, store stripe_customer_id and stripe_subscription_id
- [x] `customer.subscription.updated` → update plan tier
- [x] `customer.subscription.deleted` → downgrade to :starter
- [x] `invoice.payment_failed` → log warning, send operator email
- [x] `invoice.paid` → clear dunning state
- [x] Dunning flow: grace period (7 days) → downgrade to Starter
- [x] Grace period: features still work, admin UI shows warning banner
- [x] All events logged with Company ID for audit
- [x] Idempotent: replaying the same event is safe

## Architecture Decisions

1. **Separate controller** — `BillingWebhookController` distinct from payment `WebhookController`. Separate webhook secrets allow endpoint-level isolation in Stripe.
2. **Company lookup via stripe_customer_id** — New `:by_stripe_customer_id` read action on Company. Checkout sessions also check metadata `company_id` first.
3. **Dunning via Oban cron** — `CheckDunningGrace` runs daily at 6 AM UTC. More reliable than per-company scheduled jobs. Easy to test.
4. **Email inline, not via Oban worker** — Payment failure email sent directly in webhook handler. Webhook is already async; adding another Oban indirection is unnecessary complexity.
5. **Price ID → plan mapping** — `plan_for_price_id/1` iterates configured price IDs at runtime. No hardcoded mapping needed.

## Open Concerns

1. **Checkout plan resolution fallback** — If `checkout.session.completed` has no `plan` in metadata and no `line_items` in the event payload (Stripe doesn't always include expanded objects), defaults to `:pro`. This should be fine since BillingLive always sets `plan` in metadata, but worth noting.
2. **Single billing webhook secret** — In production, operator must configure a separate Stripe webhook endpoint for `/webhooks/stripe/billing`. If `STRIPE_BILLING_WEBHOOK_SECRET` is not set, falls back to `STRIPE_WEBHOOK_SECRET`. This is documented but could confuse operators.
3. **No dunning email deduplication** — Each `invoice.payment_failed` webhook sends an email. If Stripe sends multiple (which it does — once per retry), operator gets multiple emails. This is acceptable as a notification but could be improved with a "last notified at" check.
4. **Oban cron in test** — Test config has `testing: :manual` which disables auto-scheduling. Dunning worker tests call `perform/1` directly. Cron scheduling itself isn't tested.
