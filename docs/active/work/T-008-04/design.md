# T-008-04 Design — Browser QA for Payments

## Problem

Verify the Stripe payment flow works end-to-end in the browser. The payment LiveView has 6 states, a JS hook for Stripe.js, and interacts with an external payment processor.

## Approach Options

### Option A: Full Stripe Test Mode

- Set `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` to real Stripe test-mode keys
- Payment Element renders with real Stripe iframe
- Fill test card (4242...) via Stripe's iframe inputs
- Full E2E from page load to payment confirmation

**Pros:** Tests the real integration, catches Stripe.js loading/rendering issues
**Cons:** Requires Stripe test keys in env, Stripe iframe is hard to interact with via Playwright (cross-origin iframe), flaky due to network dependency

### Option B: Sandbox Adapter + Page State Verification

- Run with sandbox adapter (no real Stripe keys needed)
- Verify page loads, booking details display, correct DOM structure
- Payment Element won't render (fake client_secret), but we verify the container exists
- Test error/not-found states via navigation
- Simulate payment events via LiveView test helpers or JS injection to verify success/failed states

**Pros:** No external dependencies, deterministic, fast
**Cons:** Doesn't test Stripe.js rendering or real card input

### Option C: Hybrid — Sandbox for States + Stripe Test Mode for Rendering

- First pass: sandbox adapter to verify all page states (not_found, pending layout, already_paid)
- Second pass: if Stripe keys available, verify Payment Element renders in iframe
- Skip actual card fill (Stripe iframe interaction is unreliable via automation)

**Pros:** Best coverage without flakiness
**Cons:** Two-pass approach, more complex

## Decision: Option B (Sandbox + State Verification)

**Rationale:**
1. The Stripe Payment Element lives in a cross-origin iframe. Playwright cannot reliably fill form fields inside Stripe's iframe — this is a known limitation
2. The sandbox adapter is the configured default for dev. QA should test what developers actually run
3. The JS hook initialization, Stripe.js loading, and Payment Element mounting are already covered by the fact that the hook code exists and the unit tests verify LiveView event handling
4. The high-value QA targets are: page loads correctly, booking details display, correct state transitions, mobile layout works, no JS errors, no 500s
5. Previous browser QA tickets (T-002-04, T-003-04, T-005-04) focused on DOM verification and navigation, not external service interaction

**What we verify:**
- Page load and content rendering for `:pending` state (heading, amount, booking details, payment container, button)
- `:not_found` state (invalid job ID)
- Mobile viewport layout (375x812)
- No JS console errors
- No server 500 errors
- DOM structure for the Stripe hook mount point (`#stripe-payment`, `[data-stripe-element]`, `data-client-secret`, `data-publishable-key`)

**What we skip:**
- Filling card in Stripe iframe (cross-origin, unreliable)
- Real payment completion (covered by unit tests on `payment_confirmed` event)
- Webhook flow (covered by webhook_controller_test.exs)

## Test Scenarios

1. **Pending state (happy path):** Navigate to `/pay/{valid_job_id}`, verify heading, amount, booking details, payment container
2. **Not found state:** Navigate to `/pay/{random_uuid}`, verify "Job Not Found" + "Go Home"
3. **Mobile layout:** Resize to 375x812, verify no overflow, button full-width
4. **Console check:** No JS errors during page load
5. **Hook mount point:** Verify `#stripe-payment` has correct data attributes
