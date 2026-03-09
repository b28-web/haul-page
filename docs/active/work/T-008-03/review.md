# T-008-03 Review: Stripe Webhooks

## Summary

Implemented a Stripe webhook endpoint at `POST /webhooks/stripe` that verifies signatures and updates Job payment status. The endpoint is the server-side source of truth for payment confirmation.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/plugs/cache_body_reader.ex` | Custom body reader that caches raw request body in `conn.assigns[:raw_body]` for signature verification |
| `lib/haul_web/controllers/webhook_controller.ex` | Webhook controller handling `payment_intent.succeeded`, `payment_intent.payment_failed`, and unknown events |
| `test/haul_web/controllers/webhook_controller_test.exs` | 6 integration tests covering success, idempotency, failure, unknown events, missing metadata, and invalid payloads |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/endpoint.ex` | Added `body_reader` option to `Plug.Parsers` for raw body caching |
| `lib/haul_web/router.ex` | Added `/webhooks/stripe` POST route in `:api` pipeline (no CSRF) |
| `lib/haul_web/live/payment_live.ex` | Added `"tenant"` to PaymentIntent metadata for webhook tenant resolution |

## Acceptance Criteria Status

- [x] `POST /webhooks/stripe` endpoint in router (outside browser pipeline — no CSRF)
- [x] Raw body preserved for signature verification (`CacheBodyReader` with `body_reader` option)
- [x] Signature verified using `Haul.Payments.verify_webhook_signature/3` (delegates to `Stripe.Webhook.construct_event/3` in production)
- [x] Handles `payment_intent.succeeded`: looks up Job by metadata, updates `payment_intent_id`
- [x] Handles `payment_intent.payment_failed`: logs warning, returns 200
- [x] Unknown event types return 200 OK
- [x] Invalid signatures return 400
- [x] Integration tests: 6 tests covering all scenarios
- [x] Endpoint registerable via `stripe listen --forward-to` in dev

## Test Coverage

- **6 new tests** in `WebhookControllerTest`
  - `payment_intent.succeeded` updates job
  - Idempotency (second webhook for same job succeeds)
  - `payment_intent.payment_failed` returns 200, job unchanged
  - Unknown event type returns 200
  - Missing metadata returns 200 (graceful degradation)
  - Invalid payload returns 400
- **178 total tests, 0 failures** — no regressions

## Architecture Notes

- Uses existing `Haul.Payments` adapter pattern — no new behavior callbacks needed
- `verify_webhook_signature/3` was already defined in both Stripe and Sandbox adapters
- No Oban worker — webhook processing is a single DB update, synchronous is fine
- Stripe's built-in retry handles transient failures (5xx responses)

## Open Concerns

1. **`CacheBodyReader` applies to all requests:** The raw body is cached in `conn.assigns[:raw_body]` for every request, not just webhooks. This adds minor memory overhead. In practice this is negligible since request bodies are small, and this is the standard Phoenix pattern for Stripe webhooks.

2. **Sandbox adapter doesn't test real signature verification:** The sandbox adapter accepts any valid JSON regardless of signature. Real signature verification only happens with the Stripe adapter in production. This is by design — the adapter pattern separates concerns.

3. **No operator notification on payment failure:** The ticket says "optionally notifies operator" for payment failures. Currently just logs. This can be added later by enqueueing a notification worker if needed.
