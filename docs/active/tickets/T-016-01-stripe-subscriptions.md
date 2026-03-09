---
id: T-016-01
story: S-016
title: stripe-subscriptions
type: task
status: open
priority: high
phase: ready
depends_on: [T-008-01, T-013-01]
---

## Context

Set up Stripe Products and Prices for the subscription tiers. This is the billing backend — the subscription model that makes the SaaS sustainable.

## Acceptance Criteria

- Stripe Products created (via seed script or Mix task):
  - Starter (free — no Stripe product needed, just internal tracking)
  - Pro ($29/mo)
  - Business ($79/mo)
  - Dedicated ($149/mo)
- Company resource gains:
  - `subscription_plan` enum (:starter, :pro, :business, :dedicated) — default :starter
  - `stripe_customer_id` string (nullable)
  - `stripe_subscription_id` string (nullable)
- Stripe Customer created when operator first upgrades (linked to Company)
- Internal feature gate module: `Haul.Billing.can?(company, :sms_notifications)` → checks plan
- Feature gates: SMS (pro+), custom domain (pro+), payment collection (business+), crew app (business+)
