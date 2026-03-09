# T-008-01 Plan: Stripe Setup

## Step 1: Add stripity_stripe dependency
- Add `{:stripity_stripe, "~> 3.2"}` to mix.exs deps
- Run `mix deps.get`
- Verify: dep resolves and compiles

## Step 2: Configure stripity_stripe
- `config/config.exs`: add `config :stripity_stripe, api_key: ""`
- `config/config.exs`: add `config :haul, :payments_adapter, Haul.Payments.Sandbox`
- `config/test.exs`: add `config :haul, :payments_adapter, Haul.Payments.Sandbox` and `config :stripity_stripe, api_key: "sk_test_fake"`
- `config/runtime.exs`: add Stripe env var block in prod section
- Verify: `mix compile` succeeds

## Step 3: Create Haul.Payments behaviour module
- Create `lib/haul/payments.ex` with callbacks and dispatcher
- Verify: compiles

## Step 4: Create Sandbox adapter
- Create `lib/haul/payments/sandbox.ex`
- Deterministic responses, process notification for test assertions
- Verify: compiles

## Step 5: Create Stripe (production) adapter
- Create `lib/haul/payments/stripe.ex`
- Wraps `Stripe.PaymentIntent.create/1` and `Stripe.Webhook.construct_event/3`
- Verify: compiles

## Step 6: Write tests
- Create `test/haul/payments_test.exs`
- Test create_payment_intent returns success with expected fields
- Test create_payment_intent with missing required fields returns error
- Test verify_webhook_signature returns decoded event
- Test verify_webhook_signature with bad data returns error
- Run `mix test test/haul/payments_test.exs` — all pass

## Step 7: Full test suite
- Run `mix test` — all existing + new tests pass
- Run `mix compile --warnings-as-errors` — no warnings

## Testing Strategy
- All tests use Sandbox adapter (no live Stripe calls)
- Unit tests for Payments context functions
- No integration tests needed (that's T-008-02/03)
- Sandbox sends process messages for assertion patterns (matching SMS.Sandbox)
