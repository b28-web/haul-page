# T-008-03 Structure: Stripe Webhooks

## Files to Create

### `lib/haul_web/plugs/cache_body_reader.ex`
- Module `HaulWeb.Plugs.CacheBodyReader`
- Single function `read_body/2` that reads body via `Plug.Conn.read_body/2`, stores in `conn.assigns[:raw_body]`, returns `{:ok, body, conn}`
- Used as `body_reader` option on `Plug.Parsers` in endpoint

### `lib/haul_web/controllers/webhook_controller.ex`
- Module `HaulWeb.WebhookController`
- `use HaulWeb, :controller`
- Single action `stripe/2`
- Reads raw body from `conn.assigns.raw_body`
- Reads `stripe-signature` header
- Calls `Haul.Payments.verify_webhook_signature/3`
- Dispatches to private handler functions by event type
- `handle_event("payment_intent.succeeded", event)` — extracts job_id + tenant from metadata, looks up Job, calls `:record_payment`
- `handle_event("payment_intent.payment_failed", event)` — logs warning
- `handle_event(_, _)` — no-op
- Returns JSON responses: 200 `{"status": "ok"}` or 400 `{"error": "..."}`

### `test/haul_web/controllers/webhook_controller_test.exs`
- Module `HaulWeb.WebhookControllerTest`
- `use HaulWeb.ConnCase, async: false` (needs DB for tenant/job)
- Setup: create company, provision tenant, create job
- Tests:
  - `payment_intent.succeeded` updates job's `payment_intent_id`
  - `payment_intent.payment_failed` returns 200, job unchanged
  - Unknown event type returns 200
  - Invalid/missing signature returns 400
  - Missing metadata returns 200 (graceful)
  - Idempotent: second succeeded webhook for same job returns 200

## Files to Modify

### `lib/haul_web/endpoint.ex`
- Add `body_reader: {HaulWeb.Plugs.CacheBodyReader, :read_body, []}` to `Plug.Parsers` options

### `lib/haul_web/router.ex`
- Add webhook scope outside browser pipeline:
  ```
  scope "/webhooks", HaulWeb do
    pipe_through :api
    post "/stripe", WebhookController, :stripe
  end
  ```

### `lib/haul_web/live/payment_live.ex`
- Add `"tenant" => tenant` to PaymentIntent metadata (line ~28)
- Requires `tenant` to be available at that point — it's assigned as local var on line 9

## Module Boundaries

- `CacheBodyReader` — pure plug utility, no domain knowledge
- `WebhookController` — HTTP layer only, delegates to `Haul.Payments` for verification and `Ash` for Job updates
- `Haul.Payments` — existing behaviour, no changes needed (verify_webhook_signature already exists)
- `Haul.Operations.Job` — existing resource, no changes needed (`:record_payment` action exists)
