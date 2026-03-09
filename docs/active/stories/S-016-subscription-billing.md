---
id: S-016
title: subscription-billing
status: open
epics: [E-010, E-009]
---

## Subscription Billing (Phase 3)

Stripe-powered subscription management so operators pay for premium features. The Starter tier is free forever — billing only kicks in when they upgrade to Pro or above.

## Scope

- Stripe Products + Prices for each tier (Starter free, Pro $29/mo, Business $79/mo, Dedicated $149/mo)
- Company resource gains `subscription_plan` and `stripe_customer_id` fields
- Upgrade flow in `/app`: select tier → Stripe Checkout → webhook confirms → plan activated
- Downgrade flow: change plan at end of billing period, features gracefully degrade
- Stripe Customer Portal for payment method management, invoice history
- Webhook handlers: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`
- Feature gating: SMS notifications (Pro+), custom domain (Pro+), payment collection (Business+), crew app (Business+)
- Dunning: failed payment → 3 retry attempts → grace period → downgrade to Starter
- No surprise charges — usage is unlimited within tier, no per-booking fees
