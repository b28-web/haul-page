# T-008-03 Plan: Stripe Webhooks

## Step 1: CacheBodyReader plug

Create `lib/haul_web/plugs/cache_body_reader.ex` with `read_body/2` function.

Modify `lib/haul_web/endpoint.ex` to add `body_reader` option to `Plug.Parsers`.

**Verify:** Existing tests still pass (no behavioral change for non-webhook routes).

## Step 2: Add tenant to PaymentIntent metadata

Modify `lib/haul_web/live/payment_live.ex` to include `"tenant" => tenant` in the metadata map passed to `create_payment_intent`.

**Verify:** PaymentLive tests still pass.

## Step 3: Router webhook route

Add `/webhooks/stripe` POST route in router, outside browser pipeline, through `:api` pipeline.

**Verify:** `mix compile` succeeds (controller doesn't exist yet, but route can reference it).

## Step 4: WebhookController

Create `lib/haul_web/controllers/webhook_controller.ex`:
- `stripe/2` action reads raw body, verifies signature, dispatches by event type
- Private `handle_event/2` functions for succeeded, failed, and catch-all
- Returns appropriate HTTP status codes

**Verify:** `mix compile` succeeds.

## Step 5: Integration tests

Create `test/haul_web/controllers/webhook_controller_test.exs`:
- Setup creates tenant + job (same pattern as PaymentLiveTest)
- Test `payment_intent.succeeded` → job gets payment_intent_id
- Test `payment_intent.payment_failed` → 200, job unchanged
- Test unknown event → 200
- Test invalid signature → 400
- Test missing metadata → 200
- Test idempotency → second call returns 200, same result

**Verify:** `mix test test/haul_web/controllers/webhook_controller_test.exs` passes.

## Step 6: Full test suite

Run `mix test` to verify no regressions.

## Testing Strategy

- **Unit tests:** None needed — `verify_webhook_signature` is already tested in `Haul.PaymentsTest`
- **Integration tests:** WebhookControllerTest covers the full HTTP flow using Sandbox adapter
- **No Oban tests needed:** Webhook handler is synchronous
