# T-008-01 Progress: Stripe Setup

## Completed Steps

1. **Add stripity_stripe dependency** ✓
   - Added `{:stripity_stripe, "~> 3.2"}` to mix.exs
   - `mix deps.get` resolved stripity_stripe 3.2.0

2. **Configure stripity_stripe** ✓
   - `config.exs`: Sandbox adapter default + empty api_key
   - `test.exs`: Sandbox adapter + fake test key
   - `runtime.exs`: Stripe adapter when STRIPE_SECRET_KEY is set, optional STRIPE_WEBHOOK_SECRET

3. **Create Haul.Payments behaviour module** ✓
   - `lib/haul/payments.ex` with callbacks + dispatcher

4. **Create Sandbox adapter** ✓
   - `lib/haul/payments/sandbox.ex` — canned responses, process notification

5. **Create Stripe adapter** ✓
   - `lib/haul/payments/stripe.ex` — wraps stripity_stripe SDK

6. **Write tests** ✓
   - `test/haul/payments_test.exs` — 5 tests covering both functions + error cases

7. **Full test suite** ✓
   - 150 tests, 0 failures
   - `mix compile --warnings-as-errors` — clean

## Deviations from Plan
None.
