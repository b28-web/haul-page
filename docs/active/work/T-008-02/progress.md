# T-008-02 Progress: Payment Element

## Completed

### Step 1: Configuration
- Added `config :haul, :stripe_publishable_key, ""` to `config/config.exs`
- Added `STRIPE_PUBLISHABLE_KEY` env var loading in `config/runtime.exs`
- Added `deposit_amount_cents: 5000` to operator config

### Step 2: Payments Behaviour — retrieve_payment_intent
- Added `@callback retrieve_payment_intent/1` to `Haul.Payments`
- Added dispatch function `retrieve_payment_intent/1`
- Implemented in `Haul.Payments.Stripe` — calls `Stripe.PaymentIntent.retrieve/1`
- Implemented in `Haul.Payments.Sandbox` — returns canned `"succeeded"` response

### Step 3: Job Resource
- Added `payment_intent_id :string` attribute (nullable)
- Added `:record_payment` update action accepting `[:payment_intent_id]`
- Generated tenant migration: `20260309014947_add_payment_intent_id_to_jobs.exs`

### Step 4: Stripe.js in Root Layout
- Added `<script src="https://js.stripe.com/v3/"></script>` to `root.html.heex`

### Step 5: JS Hook
- Created `assets/js/hooks/stripe_payment.js` — Stripe Elements initialization, payment confirmation, error handling
- Registered `StripePayment` hook in `assets/js/app.js`
- Dark theme appearance config matching project's grayscale design

### Step 6: PaymentLive
- Created `lib/haul_web/live/payment_live.ex`
- States: `:pending`, `:processing`, `:succeeded`, `:failed`, `:not_found`, `:already_paid`, `:error`
- Mount creates PaymentIntent, assigns client_secret
- Handles `payment_confirmed`, `payment_failed`, `payment_processing` events
- Server-side verification via `retrieve_payment_intent`
- Updates Job with `payment_intent_id` on success
- Dark theme, responsive, booking details summary

### Step 7: Router
- Added `live "/pay/:job_id", PaymentLive` route

### Step 8: Tests
- Added `retrieve_payment_intent/1` test in `test/haul/payments_test.exs`
- Created `test/haul_web/live/payment_live_test.exs` with 7 tests:
  - Valid job renders payment page
  - Invalid job shows not found
  - Client secret assigned
  - Payment confirmed event updates job
  - Payment failed event shows error
  - Already paid job shows already paid
  - Processing event shows spinner

## Test Results
- 172 tests, 0 failures (was 128 → gained 44 from other tickets + 8 new)
- No compilation warnings in our code
