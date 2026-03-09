---
id: T-008-01
story: S-008
title: stripe-setup
type: task
status: open
priority: high
phase: done
depends_on: [T-001-06]
---

## Context

Add `stripity_stripe` to the project and configure it for test/dev/prod. Stripity Stripe is the most mature Elixir Stripe client — actively maintained, covers the full API, and supports webhook signature verification.

## Acceptance Criteria

- `stripity_stripe` dep added to `mix.exs`
- `config :stripity_stripe` configured in:
  - `runtime.exs`: reads `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` from env
  - `dev.exs`: uses Stripe test key (from env, not hardcoded)
  - `test.exs`: uses `Stripe.ApiMock` or a behaviour-based mock (no live API calls)
- `Haul.Payments` context module with initial `create_payment_intent/1` function wrapping `Stripe.PaymentIntent.create/1`
- Smoke test: calling `create_payment_intent(%{amount: 5000, currency: "usd"})` with test key returns a PaymentIntent struct
- Webhook signature verification helper function ready for use
- No Stripe keys in source control
