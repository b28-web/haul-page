---
id: T-016-04
story: S-016
title: browser-qa
type: task
status: open
priority: medium
phase: done
depends_on: [T-016-02, T-016-03]
---

## Context

Playwright MCP verification of the subscription billing flow. Verify the upgrade UI, Stripe Checkout redirect, and plan state changes.

## Test Plan

1. Navigate to `/app/settings/billing` as authenticated owner on Starter plan
2. Verify current plan (Starter/free) displayed with feature list
3. Verify tier comparison cards render (Starter, Pro, Business, Dedicated)
4. Click "Upgrade to Pro" — verify redirect to Stripe Checkout (test mode)
5. Verify Stripe Checkout page loads with correct price ($29/mo) and pre-filled email
6. Complete test payment with Stripe test card (4242...)
7. Verify redirect back to app with success message
8. Verify billing page now shows "Pro" as current plan
9. Verify feature gates: custom domain option now available in settings
10. Mobile (375x812): verify billing page and tier cards are readable

## Acceptance Criteria

- Full upgrade flow verified via Playwright MCP in Stripe test mode
- Plan changes reflected immediately in UI
- Feature gates activate on upgrade
