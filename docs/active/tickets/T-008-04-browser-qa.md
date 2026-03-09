---
id: T-008-04
story: S-008
title: browser-qa
type: task
status: open
priority: high
phase: done
depends_on: [T-008-02, T-008-03]
---

## Context

Automated browser QA for the payments story. Verify the Stripe Payment Element renders and the test-mode payment flow works end-to-end.

## Test Plan

1. `just dev` — ensure dev server is running (with Stripe test keys in env)
2. Create a test job in `:lead` state (via booking form or IEx)
3. Navigate to the payment page for that job
4. Verify via snapshot:
   - Stripe Payment Element iframe/container is present
   - Amount displayed correctly
   - Page is usable on mobile viewport (375x812)
5. Fill payment with Stripe test card using `browser_fill_form` or `browser_run_code`:
   - Card: 4242 4242 4242 4242
   - Exp: 12/29, CVC: 123
6. Submit payment
7. Verify success state in snapshot (confirmation message or updated status)
8. Check server logs for:
   - PaymentIntent created
   - No Stripe API errors

## Acceptance Criteria

- Payment Element renders without JS errors
- Test card payment completes successfully
- Success state displayed to user after payment
- No 500 errors in server logs
