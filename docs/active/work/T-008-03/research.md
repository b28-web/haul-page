# T-008-03 Research: Stripe Webhooks

## Existing Payment Infrastructure

### Adapter Pattern (`lib/haul/payments.ex`)
- Behaviour module with three callbacks: `create_payment_intent/1`, `retrieve_payment_intent/1`, `verify_webhook_signature/3`
- Runtime adapter selection via `Application.get_env(:haul, :payments_adapter)`
- **`verify_webhook_signature/3` already exists** — takes payload (string), signature (string), secret (string) → `{:ok, event}` or `{:error, term}`

### Stripe Adapter (`lib/haul/payments/stripe.ex`)
- Wraps `Stripe.Webhook.construct_event/3` for signature verification
- Returns the raw Stripe event struct on success

### Sandbox Adapter (`lib/haul/payments/sandbox.ex`)
- `verify_webhook_signature/3` simply does `Jason.decode(payload)`, ignores signature/secret
- Supports process-based notification via `Process.get(:payments_sandbox_pid)`

### Job Resource (`lib/haul/operations/job.ex`)
- Has `payment_intent_id` attribute (string, nullable, public)
- `:record_payment` update action — accepts only `payment_intent_id`
- No payment status field — presence of `payment_intent_id` implies paid
- Multi-tenant via AshPostgres `:context` strategy
- PaymentLive stores `job_id` in PaymentIntent metadata: `%{"job_id" => job.id}`

### Router (`lib/haul_web/router.ex`)
- Two pipelines: `:browser` (with CSRF) and `:api` (JSON only, currently commented out)
- Payment route: `live "/pay/:job_id", PaymentLive` in browser scope
- No webhook routes exist

### Endpoint (`lib/haul_web/endpoint.ex`)
- `Plug.Parsers` at line 46 consumes the raw body for all requests
- Parses `:urlencoded`, `:multipart`, `:json` with `pass: ["*/*"]`
- **Problem:** Stripe signature verification needs the raw body string, but `Plug.Parsers` consumes it before the router runs

### PaymentLive (`lib/haul_web/live/payment_live.ex`)
- Creates PaymentIntent with `metadata: %{"job_id" => job.id}`
- On `payment_confirmed`, verifies via `retrieve_payment_intent`, then calls `:record_payment`
- This is the client-side path; webhook is the server-side source of truth

### Config
- `config/config.exs`: `payments_adapter: Sandbox`, empty stripe keys
- `config/runtime.exs`: Production sets adapter to Stripe, reads `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`
- `config/test.exs`: Sandbox adapter, `Oban testing: :manual`

### Oban Setup
- `application.ex` starts `{Oban, ...}` supervisor
- Queues: `[notifications: 10]` — no payments queue yet
- Workers follow pattern: `use Oban.Worker, queue: :notifications, max_attempts: 3`
- Workers receive `job_id` and `tenant` as string args

### Test Patterns
- `Haul.PaymentsTest` — uses `ExUnit.Case, async: true` (no DB)
- `HaulWeb.PaymentLiveTest` — uses `ConnCase, async: false`, creates tenant/job in setup, cleans up tenant schemas in `on_exit`

## Key Constraints

1. **Raw body preservation:** `Plug.Parsers` consumes body before router. Need `body_reader` option or a custom plug before Parsers.
2. **Multi-tenancy:** Webhook payload won't include tenant info. Must look up job across tenants or store tenant in PaymentIntent metadata.
3. **Idempotency:** Stripe sends webhooks multiple times. Setting `payment_intent_id` is naturally idempotent.
4. **No payment status field on Job:** Currently, "paid" = `payment_intent_id != nil`. The webhook just needs to set this field.
5. **Tenant in metadata:** PaymentLive creates intent with `%{"job_id" => job.id}` but NOT tenant. Need to also store tenant in metadata for webhook lookup.

## Metadata Gap

PaymentLive line 28 creates intent with `metadata: %{"job_id" => job.id}`. The webhook handler needs `tenant` too. Options:
- Add `tenant` to metadata in PaymentLive (requires change to T-008-02 code)
- Search all tenant schemas for the job_id (expensive, fragile)
- **Best:** Add tenant to metadata. Simple, one-line change.
