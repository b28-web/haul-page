---
id: T-016-03
story: S-016
title: billing-webhooks
type: task
status: open
priority: high
phase: ready
depends_on: [T-016-01, T-008-03]
---

## Context

Handle Stripe webhook events to keep subscription state in sync. The webhook is the source of truth for billing state — the app should never poll Stripe.

## Acceptance Criteria

- `/webhooks/stripe/billing` endpoint (separate from customer-payment webhooks)
- Webhook signature verification (Stripe webhook secret in Fly secrets)
- Handled events:
  - `checkout.session.completed` → set plan, store stripe_customer_id and stripe_subscription_id
  - `customer.subscription.updated` → update plan tier
  - `customer.subscription.deleted` → downgrade to :starter
  - `invoice.payment_failed` → log warning, send operator email
  - `invoice.paid` → clear any dunning state
- Dunning flow:
  - Failed payment → Stripe retries 3x automatically
  - After final failure → grace period (7 days) → downgrade to Starter
  - Grace period: features still work, but admin UI shows warning banner
- All events logged with Company ID for audit
- Idempotent: replaying the same event is safe
