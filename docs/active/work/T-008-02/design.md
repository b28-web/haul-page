# T-008-02 Design: Payment Element

## Decision 1: How to Load Stripe.js

### Option A: CDN Script Tag in Root Layout
Add `<script src="https://js.stripe.com/v3/">` to `root.html.heex`. Always loaded on every page.

**Pros:** Simple, always available. **Cons:** Unnecessary load on non-payment pages.

### Option B: CDN Script Tag Only on Payment Page
Load Stripe.js conditionally via an assign or a separate layout.

**Pros:** Only loads when needed. **Cons:** More complex, separate layout management.

### Option C: Dynamic Script Loading in JS Hook
Hook dynamically loads Stripe.js on mount via `document.createElement('script')`.

**Pros:** Only loads when needed, no layout changes. **Cons:** Async loading adds complexity, race conditions.

**Decision: Option A.** Stripe.js is small (~30KB gzipped), cached aggressively by browsers, and adding it globally is the simplest approach. The alternative complexity isn't worth it for a single extra script tag. This matches Stripe's own recommendation.

## Decision 2: Hook Architecture

### Option A: Colocated Hook via phoenix-colocated
Define the hook inline with the LiveView template using the project's existing colocated hooks system.

### Option B: Separate JS Module in assets/js/
Create `assets/js/hooks/stripe_payment.js` and register it in `app.js`.

**Decision: Option B.** The Stripe hook has substantial JS logic (initialize Stripe, create elements, handle confirmation, error handling). A separate module is cleaner and easier to maintain. Register it alongside colocated hooks in `app.js`.

## Decision 3: Payment Amount Source

The Job resource has no `quoted_price` attribute. Options:

### Option A: Add `quoted_price` to Job, require it before payment
Operator quotes a price via admin interface, then customer pays.

### Option B: Fixed deposit amount
Use a configurable flat deposit (e.g., $50) for booking confirmation.

### Option C: Amount passed as URL parameter or determined by separate mechanism
Price computed externally and passed to the payment page.

**Decision: Option B with config.** Use a configurable deposit amount from operator config. The real-world flow is: customer books → operator quotes → customer pays deposit to confirm. For now, a fixed configurable deposit is the simplest path. Store as `:deposit_amount_cents` in operator config (default 5000 = $50). This can be extended later when a quoting mechanism exists.

## Decision 4: Server-Side Payment Confirmation

The ticket says "LiveView confirms payment status server-side before showing success."

### Option A: Retrieve PaymentIntent after client confirmation
After Stripe.js confirms payment on client, hook sends event to LiveView. LiveView calls Stripe API to retrieve PaymentIntent and verify status.

### Option B: Trust client-side confirmation
Hook reports success, LiveView shows success immediately.

### Option C: Use return_url pattern
Stripe redirects to a success URL after payment, LiveView handles the redirect.

**Decision: Option A.** Add `retrieve_payment_intent/1` to the Payments behaviour. After the hook reports a successful `confirmPayment()`, LiveView calls `retrieve_payment_intent(intent_id)` to verify status is `"succeeded"`. This is the security-correct approach — never trust client-side alone.

## Decision 5: Job Record Updates

### Option A: Add payment_intent_id to Job, update on payment
Store the Stripe PaymentIntent ID on the Job for reconciliation.

### Option B: Separate Payment record
Create a new Ash resource for payments.

**Decision: Option A.** Add `payment_intent_id` (string, nullable) attribute to Job. When payment succeeds, update Job with the intent ID. A separate Payment resource is over-engineering for the current scope. The webhook handler (T-008-03) will also use this field.

## Decision 6: LiveView Flow

1. **Mount:** Resolve tenant → load Job by ID → create PaymentIntent → assign `client_secret` and `stripe_publishable_key`
2. **Template:** Container div with `phx-hook="StripePayment"` and data attributes for client_secret and publishable_key
3. **Hook mounted:** Initialize Stripe → create Elements → mount PaymentElement into container
4. **User submits:** Hook calls `stripe.confirmPayment()` → on success, pushes `"payment_confirmed"` event with `payment_intent_id`
5. **Server handles:** Retrieves PaymentIntent → verifies `status == "succeeded"` → updates Job → assigns `:paid` state
6. **Template re-renders:** Shows success message

## Decision 7: Test Strategy

- **LiveView mount test:** Verify PaymentIntent created (sandbox), client_secret assigned, correct Job loaded
- **Event handling test:** Simulate `"payment_confirmed"` event, verify Job updated
- **Error cases:** Invalid job_id (404), already-paid job, payment failure
- **No JS/Stripe.js testing** in ExUnit — that's for Playwright (T-008-04)

## Rejected Alternatives

- **Stripe Checkout Sessions:** Redirects to Stripe-hosted page. Doesn't meet "embedded Payment Element" requirement.
- **Custom card form:** PCI compliance burden. Payment Element handles this.
- **WebSocket-based payment confirmation:** Over-complex. Simple event push is sufficient.
- **Separate Phoenix controller for payment creation:** LiveView mount is the right place — it's a single page interaction.
