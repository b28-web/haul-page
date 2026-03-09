---
id: T-008-03
story: S-008
title: stripe-webhooks
type: task
status: open
priority: high
phase: done
depends_on: [T-008-01, T-003-01]
---

## Context

Stripe confirms payment outcomes asynchronously via webhooks. Set up a webhook endpoint that verifies signatures and updates Job payment status. This is the source of truth for "did the customer actually pay" — not the client-side callback.

## Acceptance Criteria

- `POST /webhooks/stripe` endpoint in router (outside browser pipeline — no CSRF)
- Raw body preserved for signature verification (custom Plug parser or `Plug.Parsers` passthrough for this path)
- Signature verified using `Stripe.Webhook.construct_event/3` with `STRIPE_WEBHOOK_SECRET`
- Handles `payment_intent.succeeded` event: looks up Job by PaymentIntent metadata, updates payment status
- Handles `payment_intent.payment_failed` event: logs failure, optionally notifies operator
- Unknown event types return 200 OK (don't break on new Stripe events)
- Invalid signatures return 400
- Integration test: construct a mock webhook payload, verify Job state updates
- Endpoint registered in Stripe dashboard (or via `stripe listen --forward-to` in dev)
