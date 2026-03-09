# T-008-02 Review: Payment Element

## Summary

Implemented Stripe Payment Element integration via LiveView at `/pay/:job_id`. Customers can pay a configurable booking deposit using Stripe's Payment Element (supports cards, Apple Pay, Google Pay, 3D Secure). Server-side verification ensures payment status is confirmed before showing success.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/live/payment_live.ex` | LiveView for payment flow — creates PaymentIntent, handles confirmation events |
| `assets/js/hooks/stripe_payment.js` | JS hook — initializes Stripe.js, mounts Payment Element, handles confirmPayment |
| `test/haul_web/live/payment_live_test.exs` | 7 LiveView tests covering all states and event flows |
| `priv/repo/tenant_migrations/20260309014947_add_payment_intent_id_to_jobs.exs` | Adds `payment_intent_id` column to jobs |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/payments.ex` | Added `retrieve_payment_intent/1` callback + dispatch |
| `lib/haul/payments/stripe.ex` | Implemented `retrieve_payment_intent/1` via `Stripe.PaymentIntent.retrieve/1` |
| `lib/haul/payments/sandbox.ex` | Implemented `retrieve_payment_intent/1` with canned "succeeded" response |
| `lib/haul/operations/job.ex` | Added `payment_intent_id` attribute + `:record_payment` update action |
| `lib/haul_web/router.ex` | Added `live "/pay/:job_id", PaymentLive` route |
| `lib/haul_web/components/layouts/root.html.heex` | Added Stripe.js CDN script tag |
| `assets/js/app.js` | Registered StripePayment hook |
| `config/config.exs` | Added `stripe_publishable_key` and `deposit_amount_cents` config |
| `config/runtime.exs` | Added `STRIPE_PUBLISHABLE_KEY` env var loading |
| `test/haul/payments_test.exs` | Added `retrieve_payment_intent/1` test |

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `/pay/:job_id` LiveView route | ✅ |
| Mount creates PaymentIntent, passes client_secret | ✅ |
| JS hook initializes Stripe.js with publishable key | ✅ |
| JS hook mounts Payment Element | ✅ |
| On successful payment, hook sends event to LiveView | ✅ |
| LiveView confirms payment server-side before success | ✅ via `retrieve_payment_intent` |
| Stripe.js loaded from js.stripe.com | ✅ CDN script in root layout |
| Responsive Payment Element container | ✅ max-w-lg, mobile-friendly |
| Dev/test uses Stripe test mode | ✅ Sandbox adapter |

## Test Coverage

- **8 new tests** (1 unit + 7 LiveView)
- **172 total tests**, 0 failures
- Covers: mount with valid/invalid job, client_secret assignment, payment_confirmed (with Job update), payment_failed, already_paid detection, processing state
- **Not covered in ExUnit:** JS hook interaction with real Stripe.js — this is Playwright territory (T-008-04)

## Design Decisions

1. **Fixed deposit model** — No quoting mechanism exists yet, so a configurable `deposit_amount_cents` (default $50) is used. Can be extended when operator pricing is built.
2. **Server-side verification** — Added `retrieve_payment_intent/1` to Payments behaviour. LiveView verifies payment status server-side before showing success, never trusting client alone.
3. **Stripe.js loaded globally** — Added to root layout for simplicity. Small footprint (~30KB gzipped), aggressively cached.
4. **Separate JS hook file** — Rather than colocated hook, used `assets/js/hooks/stripe_payment.js` for cleaner separation of Stripe-specific JS logic.

## Open Concerns

1. **No CSP header currently set** — Stripe.js works because no Content-Security-Policy is configured. If CSP is added later (security hardening), must whitelist `js.stripe.com` (script-src) and `api.stripe.com` (connect-src).
2. **Stripe.js loads on all pages** — Could be lazy-loaded only on `/pay/` routes for performance. Low priority since it's cached after first load.
3. **No payment amount on Job** — The deposit amount comes from config, not from the Job record. When operator quoting is implemented, this should come from a `quoted_price` attribute on Job.
4. **No email/SMS notification on payment** — T-008-03 (webhooks) and notification integration will handle this.
5. **Sandbox `retrieve_payment_intent` always returns "succeeded"** — Adequate for testing happy path. May want to add a "test failure" mechanism later for testing error flows with real Sandbox.

## Cross-Ticket Notes

- **T-008-03 (webhooks):** Will use the `payment_intent_id` on Job for reconciliation. The `verify_webhook_signature` callback is already in place.
- **T-008-04 (browser QA):** Needs Playwright test with Stripe test card `4242 4242 4242 4242`. The Payment Element is mounted in a `#stripe-payment` container.
- **Other agents:** Job now has `payment_intent_id` attribute and `:record_payment` action. Migration must run before using.
