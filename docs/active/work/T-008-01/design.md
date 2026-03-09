# T-008-01 Design: Stripe Setup

## Decision: Use stripity_stripe with behaviour-based mocking

### Option A: stripity_stripe with Mox (behaviour-based mock)
Define a `Haul.Payments.StripeBehaviour` with callbacks for the Stripe operations we use. In test, Mox generates a mock. In prod, a thin adapter calls the real stripity_stripe functions.

**Pros:** Clean separation, testable without HTTP mocking, follows existing SMS pattern.
**Cons:** Extra indirection layer, must define/maintain behaviour callbacks as Stripe usage grows.

### Option B: stripity_stripe with custom HTTP client
stripity_stripe supports configuring a custom HTTP client module. Swap in a test client that returns canned responses.

**Pros:** Tests exercise more of the real code path (serialization, struct parsing).
**Cons:** Requires maintaining fixture JSON, more brittle to Stripe API changes, doesn't match SMS pattern.

### Option C: Direct stripity_stripe calls with Bypass
Use Bypass to intercept HTTP in tests.

**Pros:** Full integration-style tests.
**Cons:** Heavy, slow, doesn't match project conventions (SMS uses behaviour pattern).

### Decision: Option A — Behaviour-based adapter (matches SMS pattern)

Rationale:
1. The project already uses this pattern for SMS (`Haul.SMS` behaviour + `Sandbox`/`Twilio` adapters)
2. Keeps tests fast and deterministic — no HTTP involved
3. Acceptance criteria explicitly mention "behaviour-based mock"
4. Easy to extend as more Stripe operations are needed (T-008-02, T-008-03)

### Architecture

```
Haul.Payments (context module)
├── @callback create_payment_intent(params) :: {:ok, map()} | {:error, term()}
├── @callback verify_webhook_signature(payload, sig, secret) :: {:ok, map()} | {:error, term()}
│
├── Haul.Payments.Stripe   — prod adapter (calls stripity_stripe)
└── Haul.Payments.Sandbox   — dev/test adapter (returns canned data)
```

- `Haul.Payments` defines the behaviour and dispatches via `Application.get_env(:haul, :payments_adapter)`
- Config follows the same pattern as SMS:
  - `config.exs`: `config :haul, :payments_adapter, Haul.Payments.Sandbox`
  - `runtime.exs`: overrides to `Haul.Payments.Stripe` when `STRIPE_SECRET_KEY` is set
  - `test.exs`: `config :haul, :payments_adapter, Haul.Payments.Sandbox`

### stripity_stripe Config
- `config :stripity_stripe, api_key: "sk_test_..."` — set in runtime.exs from env var
- `config :stripity_stripe, signing_secret: "whsec_..."` — for webhook verification
- dev.exs: reads from env vars (not hardcoded)
- test.exs: set a dummy key; the Sandbox adapter bypasses Stripe SDK anyway

### Webhook Verification
- `verify_webhook_signature/3` wraps `Stripe.Webhook.construct_event/3`
- Ready for T-008-03 to use in the webhook controller
- Sandbox returns `{:ok, decoded_payload}` for testing

### What This Ticket Does NOT Do
- No Stripe Elements UI (T-008-02)
- No webhook endpoint/controller (T-008-03)
- No Ash resource for payments
- No database changes
