# T-008-02 Plan: Payment Element

## Step 1: Configuration — Stripe Publishable Key

**Files:** `config/config.exs`, `config/runtime.exs`

- Add `config :haul, :stripe_publishable_key, ""` to `config.exs`
- Add `STRIPE_PUBLISHABLE_KEY` loading in `runtime.exs` prod block alongside secret key
- **Verify:** `Application.get_env(:haul, :stripe_publishable_key)` returns empty string in dev

## Step 2: Payments Behaviour — Add retrieve_payment_intent

**Files:** `lib/haul/payments.ex`, `lib/haul/payments/stripe.ex`, `lib/haul/payments/sandbox.ex`

- Add `@callback retrieve_payment_intent(id :: String.t()) :: {:ok, map()} | {:error, term()}`
- Add `def retrieve_payment_intent(id), do: adapter().retrieve_payment_intent(id)` dispatch
- Stripe adapter: `Stripe.PaymentIntent.retrieve(id)` → normalize to map
- Sandbox adapter: return `%{id: id, status: "succeeded", ...}` canned response
- **Verify:** `Haul.Payments.retrieve_payment_intent("pi_test")` returns `{:ok, %{status: "succeeded"}}`

## Step 3: Job Resource — Add payment_intent_id + record_payment action

**Files:** `lib/haul/operations/job.ex`

- Add attribute `payment_intent_id :string, allow_nil? true, public? true`
- Add update action `:record_payment` accepting `[:payment_intent_id]`
- Generate migration: `mix ash.codegen add_payment_intent_id_to_jobs`
- **Verify:** `mix test` still passes (no breaking changes)

## Step 4: Stripe.js in Root Layout

**Files:** `lib/haul_web/components/layouts/root.html.heex`

- Add `<script src="https://js.stripe.com/v3/"></script>` before the app.js script tag
- **Verify:** Dev server loads without errors, Stripe.js available in browser console (`window.Stripe`)

## Step 5: Stripe Payment JS Hook

**Files:** `assets/js/hooks/stripe_payment.js`, `assets/js/app.js`

Create `assets/js/hooks/stripe_payment.js`:
- `mounted()`: read data attributes, init Stripe, create Elements with appearance (dark theme), mount PaymentElement
- Form submit handler: `stripe.confirmPayment()` with `redirect: "if_required"`
- On success: `this.pushEvent("payment_confirmed", {payment_intent_id})`
- On error: `this.pushEvent("payment_failed", {error: message})`

Update `assets/js/app.js`:
- Import StripePayment hook
- Add to hooks spread

**Verify:** JS builds without errors (`mix assets.build` or esbuild)

## Step 6: PaymentLive LiveView

**Files:** `lib/haul_web/live/payment_live.ex`

Implement LiveView:
- `mount/3` with `%{"job_id" => job_id}` params
- Resolve tenant, load Job, handle not-found
- Create PaymentIntent with amount from config deposit
- Assign `client_secret`, `publishable_key`, `job`, `payment_status`
- Handle `"payment_confirmed"` — retrieve + verify + update Job
- Handle `"payment_failed"` — show error
- Render with hook container, states for pending/processing/succeeded/failed
- Dark theme styling matching BookingLive patterns
- Mobile responsive Payment Element container

**Verify:** Route accessible in dev (needs a Job to exist)

## Step 7: Router

**Files:** `lib/haul_web/router.ex`

- Add `live "/pay/:job_id", PaymentLive` in browser scope
- **Verify:** `mix phx.routes` shows new route

## Step 8: Tests

**Files:** `test/haul_web/live/payment_live_test.exs`, `test/haul/payments_test.exs`

Payment behaviour tests (extend existing):
- `retrieve_payment_intent/1` returns `{:ok, %{status: "succeeded"}}`

LiveView tests:
- Mount with valid job_id → renders payment container with client_secret
- Mount with invalid job_id → error state
- `payment_confirmed` event → success state, Job has payment_intent_id
- `payment_failed` event → error state with message

**Verify:** `mix test` passes, all new tests green

## Step 9: Deposit Amount Config

**Files:** `config/config.exs`

- Add `deposit_amount_cents: 5000` to operator config
- PaymentLive reads from operator config for the PaymentIntent amount
- **Verify:** Config accessible, PaymentIntent created with correct amount

## Testing Strategy

- **Unit:** Payments.retrieve_payment_intent via Sandbox
- **LiveView:** Mount, event handling, state transitions
- **No JS testing** — Stripe.js interaction is for Playwright (T-008-04)
- **Integration:** Full flow from mount → payment_confirmed → Job updated
