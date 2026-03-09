# T-008-04 Plan — Browser QA for Payments

## Prerequisites

- Dev server running: `just dev`
- Playwright MCP available
- Tenant provisioned with Job in `:lead` state

## Step 0: Setup

1. Verify dev server is running at `http://localhost:4000`
2. Get a valid job_id for testing — either from an existing job or create one via `/book`
3. Record the job_id for use in subsequent steps

## Step 1: Payment Page Load (Pending State)

1. `browser_navigate` to `http://localhost:4000/pay/{job_id}`
2. `browser_snapshot` — capture initial state
3. **Verify:**
   - H1 heading: "Complete Payment"
   - Amount text: "Booking deposit: $50.00"
   - Booking Details section with Name, Address, Items
   - Payment container present (`#stripe-payment`)
   - Pay button: "Pay $50.00"
   - Security note: "Payments processed securely by Stripe"
4. **Pass criteria:** All elements present, page renders without errors

## Step 2: Hook Mount Point Verification

1. From the same snapshot, verify DOM structure:
   - `#stripe-payment` element exists with `phx-hook="StripePayment"`
   - `data-client-secret` attribute present (sandbox: `pi_sandbox_secret_*`)
   - `data-publishable-key` attribute present
   - `[data-stripe-element]` container inside the form
   - Form has `id="payment-form"`
2. **Pass criteria:** All data attributes present for JS hook initialization

## Step 3: Console Error Check

1. `browser_console_messages` — check for JS errors
2. **Verify:** No error-level console messages
3. **Note:** Stripe.js may log warnings about invalid keys (sandbox mode) — warnings are acceptable, errors are not
4. **Pass criteria:** No JS errors (warnings OK)

## Step 4: Not Found State

1. `browser_navigate` to `http://localhost:4000/pay/00000000-0000-0000-0000-000000000000`
2. `browser_snapshot` — capture not-found state
3. **Verify:**
   - H1 heading: "Job Not Found"
   - Message: "The booking you're looking for doesn't exist or the link has expired."
   - "Go Home" link present, pointing to "/"
4. **Pass criteria:** Not-found state renders correctly

## Step 5: Mobile Viewport (375x812)

1. `browser_resize` to 375x812
2. `browser_navigate` to `http://localhost:4000/pay/{job_id}`
3. `browser_snapshot` — capture mobile state
4. **Verify:**
   - All content visible without horizontal scroll
   - Pay button full-width
   - Booking details readable
   - Amount displayed correctly
5. **Pass criteria:** Layout adapts to mobile, all elements accessible

## Step 6: Server Health Check

1. Check dev server logs for any 500 errors during test session
2. **Pass criteria:** No 500 errors logged

## Bug Handling

- If page doesn't load → check dev server, ensure tenant provisioned
- If not-found doesn't render → check router, may need valid UUID format
- Trivial display issues → document in progress.md, fix if straightforward
- Complex issues → document for separate ticket
