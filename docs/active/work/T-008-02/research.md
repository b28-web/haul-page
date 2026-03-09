# T-008-02 Research: Payment Element

## Existing Payments Infrastructure (T-008-01)

### Behaviour + Adapter Pattern
- `lib/haul/payments.ex` — behaviour module with two callbacks:
  - `create_payment_intent(params)` → `{:ok, map()} | {:error, term()}`
  - `verify_webhook_signature(payload, signature, secret)` → `{:ok, map()} | {:error, term()}`
- `lib/haul/payments/stripe.ex` — production adapter wrapping `stripity_stripe`
- `lib/haul/payments/sandbox.ex` — dev/test adapter returning deterministic canned responses
- Adapter selected via `Application.get_env(:haul, :payments_adapter, Haul.Payments.Sandbox)`

### Sandbox Adapter Behaviour
- `create_payment_intent/1` returns: `%{id: "pi_sandbox_...", object: "payment_intent", amount, currency, status: "requires_payment_method", client_secret: "pi_sandbox_secret_...", metadata}`
- Sends `{:payment_intent_created, result}` to `Process.get(:payments_sandbox_pid)` for test assertions
- `verify_webhook_signature/3` just decodes JSON payload (no signature verification)

### Configuration
- `config.exs`: `payments_adapter` defaults to Sandbox, `stripity_stripe api_key: ""`
- `runtime.exs` (prod only): activates Stripe adapter when `STRIPE_SECRET_KEY` env var is set
- No `STRIPE_PUBLISHABLE_KEY` config yet — needed for client-side Stripe.js

## Job Resource (Operations Domain)

- `lib/haul/operations/job.ex` — Ash resource with state machine
- States: `:lead` (initial) — transitions not yet defined
- Attributes: `id`, `customer_name`, `customer_phone`, `customer_email`, `address`, `item_description`, `preferred_dates`, `notes`, `photo_urls`, timestamps
- No `payment_intent_id` or `quoted_price` attribute yet — will need one to link payment
- Multi-tenant via `:context` strategy
- Single create action: `:create_from_online_booking`

## LiveView Pattern (BookingLive)

- `lib/haul_web/live/booking_live.ex` — reference implementation
- Mount: resolves tenant via `ContentHelpers.resolve_tenant()`, loads site config
- Uses `AshPhoenix.Form` for form binding
- Renders inline via `~H` sigil (no separate template file)
- Dark theme styling: `bg-background text-foreground`, Oswald for headings
- Pattern for state transitions: `@submitted` assign toggles between form and success view

## Router

- `lib/haul_web/router.ex` — browser pipeline with standard Phoenix plugs
- Current routes: `/` (PageController), `/scan` (ScanLive), `/book` (BookingLive), `/scan/qr` (QRController)
- No `/pay/:job_id` route yet

## JavaScript / Asset Pipeline

- `assets/js/app.js` — LiveSocket with colocated hooks from `phoenix-colocated/haul`
- Hook registration: `hooks: {...colocatedHooks}` — new hooks can be added via spread
- esbuild bundles `js/app.js` → `priv/static/assets/js/app.js`
- No external CDN scripts currently loaded

## Root Layout & CSP

- `lib/haul_web/components/layouts/root.html.heex` — loads `app.css` and `app.js`
- Contains inline `<script>` for theme switching (localStorage-based)
- No explicit CSP meta tag or header — Phoenix default `put_secure_browser_headers` does not set CSP
- Stripe.js requires loading from `https://js.stripe.com/v3/` — since no CSP is set, this will work by default
- If CSP is added later, must allow `script-src https://js.stripe.com` and `connect-src https://api.stripe.com`

## Endpoint

- `lib/haul_web/endpoint.ex` — standard Phoenix endpoint
- No CSP plug configuration
- Session stored in cookie, signed with `same_site: "Lax"`

## Testing Infrastructure

- `test/haul/payments_test.exs` — 5 tests for Sandbox adapter
- Test pattern: direct function calls with assertions on return values
- Sandbox notification via `Process.put(:payments_sandbox_pid, self())`
- LiveView tests exist: `test/haul_web/live/booking_live_upload_test.exs`, `test/haul_web/live/scan_live_test.exs`
- 128 total tests passing

## Key Constraints

1. **No node_modules** — JS deps are vendored or loaded from CDN. Stripe.js must be CDN (`js.stripe.com`).
2. **Stripe.js cannot be bundled** — Stripe requires loading from their CDN for PCI compliance.
3. **Sandbox adapter** must work in tests — LiveView tests won't have real Stripe, so hook initialization must be skippable/mockable in tests.
4. **Job has no price attribute** — need to decide how PaymentIntent amount is determined. Ticket says "quoted job" but no quoting mechanism exists yet.
5. **No `retrieve_payment_intent` callback** — only `create` and `verify_webhook`. May need to add a retrieve/confirm callback for server-side verification.
6. **Phoenix colocated hooks** — the project uses `phoenix-colocated` for hooks, meaning hooks can be defined alongside LiveView templates.

## Files That Will Be Modified/Created

- New: `lib/haul_web/live/payment_live.ex` — PaymentLive LiveView
- New: `assets/js/stripe_hook.js` or colocated hook — Stripe.js initialization
- Modified: `lib/haul_web/router.ex` — add `/pay/:job_id` route
- Modified: `lib/haul_web/components/layouts/root.html.heex` — add Stripe.js CDN script
- Modified: `lib/haul/payments.ex` — possibly add `retrieve_payment_intent` callback
- Modified: `lib/haul/payments/sandbox.ex` — possibly add retrieve callback
- Modified: `config/config.exs` or `config/runtime.exs` — add publishable key config
- New: `test/haul_web/live/payment_live_test.exs` — LiveView tests
