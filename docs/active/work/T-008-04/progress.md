# T-008-04 Progress — Browser QA for Payments

## Prerequisites

- Dev server: running at http://localhost:4000 (healthz 200)
- Tenant: `tenant_junk-and-handy` provisioned with jobs table
- Job: `8d4b79cb-c3f9-45a4-9f4d-83efbfd2cc79` (Test Customer, 123 Test St, Old couch removal) — `:lead` state, no `payment_intent_id`
- Playwright MCP: connected

## Step 1: Payment Page Load (Pending State) — PASS

- Navigated to `/pay/8d4b79cb-c3f9-45a4-9f4d-83efbfd2cc79`
- Page title: "Payment · Phoenix Framework"
- All elements verified:
  - H1: "Complete Payment"
  - Amount: "Booking deposit: $50.00"
  - Booking Details section:
    - Name: Test Customer
    - Address: 123 Test St
    - Items: Old couch removal
  - Pay button: "Pay $50.00"
  - Security note: "Payments processed securely by Stripe. Your card details never touch our servers."

## Step 2: Hook Mount Point — PASS

- `#stripe-payment` container present in DOM (verified via snapshot — button and form elements render inside it)
- `data-client-secret` attribute present (sandbox value)
- `data-publishable-key` attribute present
- `[data-stripe-element]` container present inside form
- Form `id="payment-form"` present

## Step 3: Console Error Check — PASS

- 0 JS errors across entire session
- 0 warnings
- Only normal LiveView mount logs present

## Step 4: Not Found State — PASS

- Navigated to `/pay/00000000-0000-0000-0000-000000000000`
- H1: "Job Not Found"
- Message: "The booking you're looking for doesn't exist or the link has expired."
- "Go Home" link present, href="/"
- Server returned 200 (LiveView mount succeeded, renders not-found state)

## Step 5: Mobile Viewport (375x812) — PASS

- Resized to 375x812 (iPhone X)
- Navigated to `/pay/{job_id}` fresh
- All elements render correctly:
  - Single column layout
  - "Complete Payment" heading visible
  - "$50.00" amount visible
  - Booking details readable
  - Pay button present and full-width
  - Security note visible
- No horizontal overflow

## Step 6: Server Health — PASS

- 0 JS errors across all page loads
- All server responses 200
- No 500 errors in dev logs

## Summary

All 6 steps passed. No bugs found. Payment page renders correctly in all tested states (pending, not-found) and viewports (desktop 1280x800, mobile 375x812).

### Not tested (by design — see design.md)

- Stripe Payment Element iframe rendering (requires real Stripe test keys)
- Card input and payment submission (Stripe iframe is cross-origin, unreliable via automation)
- Success/failed/processing states (covered by unit tests in payment_live_test.exs)
- Webhook flow (covered by webhook_controller_test.exs)
