---
id: T-008-02
story: S-008
title: payment-element
type: task
status: open
priority: high
phase: done
depends_on: [T-008-01, T-003-02]
---

## Context

Embed Stripe's Payment Element in a LiveView page so customers can pay for a quoted job. The Payment Element handles card collection, Apple Pay, Google Pay, and 3D Secure — no PCI scope on our side.

## Acceptance Criteria

- `/pay/:job_id` LiveView route (or inline on a job detail page)
- LiveView mount creates a PaymentIntent server-side via `Haul.Payments`, passes `client_secret` to the client
- JS hook initializes Stripe.js with the publishable key and mounts the Payment Element
- On successful payment, hook sends event back to LiveView
- LiveView confirms payment status server-side before showing success
- Stripe.js loaded from `js.stripe.com` (not vendored) — CSP header allows it
- Works on mobile browsers (responsive Payment Element container)
- Dev/test uses Stripe test mode — card `4242 4242 4242 4242` completes successfully
