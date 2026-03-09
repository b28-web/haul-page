# T-008-01 Review: Stripe Setup

## Summary

Added `stripity_stripe` dependency and created `Haul.Payments` context module with behaviour-based adapter pattern (matching the existing `Haul.SMS` pattern). Payments are configured for dev/test (Sandbox) and prod (Stripe via env vars).

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/payments.ex` | Behaviour + dispatcher module |
| `lib/haul/payments/sandbox.ex` | Dev/test adapter — canned responses |
| `lib/haul/payments/stripe.ex` | Production adapter — wraps stripity_stripe SDK |
| `test/haul/payments_test.exs` | 5 tests for create_payment_intent and verify_webhook_signature |

## Files Modified

| File | Change |
|------|--------|
| `mix.exs` | Added `{:stripity_stripe, "~> 3.2"}` |
| `config/config.exs` | Added `payments_adapter` + `stripity_stripe` defaults |
| `config/test.exs` | Added Sandbox adapter + fake API key |
| `config/runtime.exs` | Added Stripe config block (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET) |

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `stripity_stripe` dep added to mix.exs | ✓ |
| `config :stripity_stripe` in runtime.exs (env vars) | ✓ |
| Dev uses test key from env (not hardcoded) | ✓ (Sandbox adapter, no key needed) |
| Test uses behaviour-based mock (no live API) | ✓ (Sandbox adapter) |
| `Haul.Payments` context with `create_payment_intent/1` | ✓ |
| Smoke test: `create_payment_intent(%{amount: 5000, currency: "usd"})` works | ✓ |
| Webhook signature verification helper ready | ✓ (`verify_webhook_signature/3`) |
| No Stripe keys in source control | ✓ (env vars only) |

## Test Coverage

- 5 new tests in `test/haul/payments_test.exs`
- Tests cover: successful payment intent creation, metadata passthrough, missing params error, valid webhook verification, invalid payload error
- Full suite: 150 tests, 0 failures
- No compilation warnings

## Architecture Decisions

- **Behaviour pattern over Mox** — used the same approach as `Haul.SMS`: a behaviour module with adapter dispatch via application config. Keeps things simple without adding Mox dependency.
- **Sandbox process notification** — `Process.put(:payments_sandbox_pid, self())` enables test assertions via `assert_received`. Same pattern as `Haul.SMS.Sandbox`.
- **Normalized return maps** — both adapters return the same map shape (`id`, `object`, `amount`, `currency`, `status`, `client_secret`, `metadata`) regardless of source.

## Open Concerns

- **Stripe adapter untested against live API** — by design (no keys in test). The Stripe adapter is a thin wrapper; correctness depends on stripity_stripe.
- **No `create_customer` yet** — Company already has `stripe_customer_id` attribute but no function to create Stripe customers. This will likely be needed in T-008-02 or T-016-01.
- **Webhook construct_event return type** — the Sandbox returns a plain map from JSON decode; the Stripe adapter returns whatever `Stripe.Webhook.construct_event` returns (a `Stripe.Event` struct). Consumers will need to handle both. T-008-03 should normalize this.

## Ready For

- T-008-02 (payment-element) can call `Haul.Payments.create_payment_intent/1` from LiveView
- T-008-03 (stripe-webhooks) can use `Haul.Payments.verify_webhook_signature/3` in a controller
