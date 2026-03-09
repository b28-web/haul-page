# T-008-03 Design: Stripe Webhooks

## Problem

Stripe webhook endpoint that verifies signatures, parses events, and updates Job payment status as the server-side source of truth.

## Key Decisions

### 1. Raw Body Preservation

**Options:**
- A) Custom `body_reader` on `Plug.Parsers` — cache raw body in `conn.assigns` for all requests
- B) Custom plug before `Plug.Parsers` that caches body only for webhook path
- C) Separate `Plug.Parsers` config for webhook route via a plug in the pipeline

**Decision: A — `body_reader` option on `Plug.Parsers`**

Rationale: Phoenix/Plug supports `body_reader: {Module, :read_body, []}` option on `Plug.Parsers`. We create a `CacheBodyReader` module that stores the raw body in `conn.assigns[:raw_body]` before returning it for normal parsing. This is the standard Phoenix pattern for Stripe webhooks — minimal code, no request path matching needed.

### 2. Controller vs Plug

**Decision: Phoenix Controller**

A standard controller is simpler, more testable, and follows the existing pattern (HealthController, PageController). The controller reads raw body from assigns, verifies signature, dispatches by event type.

### 3. Tenant Resolution in Webhooks

**Decision: Store tenant in PaymentIntent metadata**

PaymentLive currently creates intents with `%{"job_id" => job.id}`. We add `"tenant" => tenant` to the metadata map. The webhook handler reads both from event metadata. One-line change to PaymentLive.

### 4. Event Handling

Events to handle:
- `payment_intent.succeeded` → look up Job by ID from metadata, call `:record_payment` with tenant
- `payment_intent.payment_failed` → log warning with job details, return 200

All other events → return 200 OK (Stripe best practice).

### 5. Idempotency

Setting `payment_intent_id` on a Job that already has it is harmless — Ash will update to the same value. No special idempotency logic needed.

### 6. Failed Payment Handling

For `payment_intent.payment_failed`, we log the failure. No DB state change needed — the Job simply doesn't have a `payment_intent_id` set. The customer can retry via PaymentLive. Future tickets can add operator notification if desired.

### 7. Error Handling

- Invalid signature → 400 with `{"error": "invalid_signature"}`
- Missing metadata (job_id/tenant) → log warning, return 200 (don't make Stripe retry)
- Job not found → log warning, return 200
- Unknown event type → return 200

### 8. No Oban Worker

The webhook handler is synchronous and fast — one DB read + one DB update. No need for an Oban worker. If the webhook fails (5xx), Stripe retries automatically. Adding Oban would add complexity for no benefit.

## Rejected Approaches

- **Oban worker for webhook processing:** Unnecessary complexity. The operation is a single DB update. Stripe's retry mechanism handles failures.
- **Searching all tenant schemas:** Fragile and slow. Storing tenant in metadata is cleaner.
- **Separate Plug.Parsers for webhook pipeline:** More complex than `body_reader` option, which is the standard pattern.
