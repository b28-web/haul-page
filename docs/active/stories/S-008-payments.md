---
id: S-008
title: payments
status: open
epics: [E-009, E-004, E-006]
---

## Payment Processing (Stripe)

Integrate Stripe for collecting payments on completed jobs. Uses Stripity Stripe (well-maintained Hex package) for server-side API calls and Stripe.js / Payment Element for client-side card collection.

## Scope

- Stripe account connection per operator (env var for API key, one key per deploy)
- Create PaymentIntent when operator sends an invoice / quote acceptance
- Stripe Payment Element embedded in LiveView via JS hook
- Webhook endpoint to receive payment confirmation events
- Link payment status back to Job resource via AshDoubleEntry ledger (future)
- Test mode with Stripe's test keys in dev/CI — no live charges outside production
