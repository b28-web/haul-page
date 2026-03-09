# T-008-02 Structure: Payment Element

## New Files

### `lib/haul_web/live/payment_live.ex`
LiveView for `/pay/:job_id` route.

- `mount/3` — params has `job_id`, resolves tenant, loads Job via `Ash.get(Job, id, tenant: tenant)`, creates PaymentIntent via `Haul.Payments.create_payment_intent/1`, assigns `client_secret`, `stripe_publishable_key`, `job`, `payment_status` (`:pending | :processing | :succeeded | :failed`)
- `handle_event("payment_confirmed", %{"payment_intent_id" => id}, socket)` — calls `Haul.Payments.retrieve_payment_intent(id)`, verifies status, updates Job with `payment_intent_id`, sets `payment_status` to `:succeeded`
- `handle_event("payment_failed", %{"error" => msg}, socket)` — sets `payment_status` to `:failed`, assigns error message
- `render/1` — three states: pending (shows Payment Element container), processing (spinner), succeeded (success message), failed (error + retry)

### `assets/js/hooks/stripe_payment.js`
LiveView hook for Stripe.js Payment Element.

- `mounted()` — reads `data-client-secret` and `data-publishable-key` from element, initializes `Stripe(publishableKey)`, creates `elements` with `clientSecret`, creates and mounts `PaymentElement`
- `handleSubmit()` — called from form submit, calls `stripe.confirmPayment()`, pushes result event to LiveView
- `destroyed()` — cleanup: unmount elements
- Exports as default hook object with `mounted`, `destroyed` callbacks

### `test/haul_web/live/payment_live_test.exs`
LiveView tests using ConnCase + Sandbox adapter.

- Test mount with valid job_id → assigns client_secret
- Test mount with invalid job_id → error/redirect
- Test payment_confirmed event → Job updated
- Test payment_failed event → error displayed

## Modified Files

### `lib/haul_web/router.ex`
Add route: `live "/pay/:job_id", PaymentLive`

### `lib/haul_web/components/layouts/root.html.heex`
Add Stripe.js CDN script tag in `<head>`: `<script src="https://js.stripe.com/v3/"></script>`

### `assets/js/app.js`
Import and register StripePayment hook:
```js
import StripePayment from "./hooks/stripe_payment"
const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...colocatedHooks, StripePayment},
})
```

### `lib/haul/payments.ex`
Add `retrieve_payment_intent/1` callback and dispatch function.

### `lib/haul/payments/stripe.ex`
Implement `retrieve_payment_intent/1` — calls `Stripe.PaymentIntent.retrieve/1`.

### `lib/haul/payments/sandbox.ex`
Implement `retrieve_payment_intent/1` — returns canned response with `status: "succeeded"`.

### `lib/haul/operations/job.ex`
- Add attribute: `payment_intent_id :string, allow_nil? true, public? true`
- Add update action: `:record_payment` accepting `payment_intent_id`
- Add read action or use defaults: `:read` already exists (via `defaults [:read]`)

### `config/config.exs`
Add `stripe_publishable_key: ""` to operator or payments config.

### `config/runtime.exs`
Add `STRIPE_PUBLISHABLE_KEY` env var loading alongside `STRIPE_SECRET_KEY`.

## Module Boundaries

- `Haul.Payments` — pure payment processing, no Job knowledge
- `HaulWeb.PaymentLive` — orchestrates: loads Job, creates intent, handles confirmation, updates Job
- `assets/js/hooks/stripe_payment.js` — pure client-side Stripe interaction, communicates via LiveView events

## Ordering Constraints

1. Config changes (publishable key) — first, no dependencies
2. Payments behaviour + adapters (retrieve callback) — before LiveView
3. Job resource changes (payment_intent_id attribute + action) — before LiveView
4. Migration for new Job column — after Job resource change
5. PaymentLive + hook + route + layout — after steps 2-4
6. Tests — after all implementation
