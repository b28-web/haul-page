---
id: T-016-02
story: S-016
title: upgrade-flow
type: task
status: open
priority: high
phase: ready
depends_on: [T-016-01]
---

## Context

Build the upgrade/downgrade flow in the operator admin UI. Operator selects a tier, pays via Stripe Checkout, and their plan activates.

## Acceptance Criteria

- `/app/settings/billing` LiveView
- Current plan displayed with feature list
- Upgrade: select new tier → redirect to Stripe Checkout → return to app
- Downgrade: select lower tier → confirmation ("changes at end of billing period") → Stripe API call
- Stripe Checkout session created with:
  - `mode: "subscription"`
  - `success_url` and `cancel_url` back to app
  - Customer email pre-filled
- Manage payment methods: link to Stripe Customer Portal
- Invoice history: link to Stripe Customer Portal
- Visual: clear comparison of tiers with current plan highlighted
