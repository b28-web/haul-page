# T-008-04 Research — Browser QA for Payments

## Scope

Browser QA for the Stripe payment flow. Verify Payment Element renders, test-mode payment works, and success/error states display correctly. This is a QA-only ticket — no code changes expected.

## Payment Flow Architecture

1. Customer books at `/book` → Job created in `:lead` state (no `payment_intent_id`)
2. Customer visits `/pay/{job_id}` → PaymentLive mounts
3. LiveView calls `Haul.Payments.create_payment_intent/1` → gets `client_secret`
4. JS hook (`StripePayment`) initializes Stripe.js, mounts Payment Element
5. Customer fills card → hook calls `stripe.confirmPayment()`
6. Hook pushes `payment_confirmed` or `payment_failed` to LiveView
7. LiveView verifies intent server-side via `retrieve_payment_intent/1`
8. On success: updates Job with `payment_intent_id` via `:record_payment` action

## Key Files

| File | Role |
|------|------|
| `lib/haul_web/live/payment_live.ex` | LiveView: mount, events, 6 render states |
| `assets/js/hooks/stripe_payment.js` | JS hook: Stripe.js init, confirmPayment, event push |
| `lib/haul/payments.ex` | Behaviour + adapter dispatch |
| `lib/haul/payments/sandbox.ex` | Dev/test adapter — canned responses |
| `lib/haul/payments/stripe.ex` | Production adapter — stripity_stripe |
| `lib/haul_web/controllers/webhook_controller.ex` | POST `/webhooks/stripe` |
| `lib/haul_web/components/layouts/root.html.heex` | Stripe.js CDN `<script>` tag |

## Payment States (render branches)

| State | Trigger | Display |
|-------|---------|---------|
| `:not_found` | Invalid job_id | "Job Not Found" + "Go Home" link |
| `:already_paid` | Job has `payment_intent_id` | "Already Paid" confirmation |
| `:error` | PaymentIntent creation failed | Error message + "Try Again" link |
| `:pending` | Normal load | Booking details + Payment Element + "Pay $50.00" button |
| `:processing` | `payment_processing` event | Spinner + "Processing Payment" |
| `:succeeded` | Verified payment | "Payment Received!" + phone CTA |
| `:failed` | Payment error | Error message + "Try Again" link |

## Adapter Configuration

- Dev/test: `Haul.Payments.Sandbox` — no real Stripe calls
- Production: `Haul.Payments.Stripe` when `STRIPE_SECRET_KEY` env var set

**Critical QA limitation:** In dev with sandbox adapter, `client_secret` is a fake string (`pi_sandbox_secret_*`). Stripe.js will fail to initialize a real Payment Element with a fake secret. Real Stripe test keys are needed for the Payment Element to render.

## Stripe.js Hook Details

- Reads `data-client-secret` and `data-publishable-key` from element dataset
- Creates Stripe instance, creates Elements with "night" theme
- Mounts `payment` element to `[data-stripe-element]` container
- Form submit → `stripe.confirmPayment()` with `redirect: "if_required"`
- Appearance: dark theme, white primary, Source Sans 3 font, 0px border-radius

## Existing Tests (Unit/Integration)

- 7 PaymentLive tests (mount, events, states)
- 6 WebhookController tests (event handling, signature verification)
- 6 Payments adapter tests (sandbox create/retrieve/verify)
- **Gap:** No browser-level E2E test with real Stripe.js rendering

## Prerequisites for Browser QA

1. Dev server running (`just dev`)
2. Tenant provisioned (Company + schema with jobs table)
3. Job in `:lead` state with no `payment_intent_id`
4. For Payment Element rendering: Stripe test keys in env (or accept sandbox limitation)
5. Playwright MCP connected

## Prior Browser QA Pattern (T-003-04)

Previous QA tickets follow: navigate → snapshot → verify elements → interact → snapshot → verify states → mobile viewport → server health check. Screenshots saved to work directory.
