# T-008-01 Research: Stripe Setup

## Existing Codebase State

### Dependencies (mix.exs)
- Phoenix 1.8.5, Ash 3.19, AshPostgres 2.7
- Already has: `ash_money`, `ash_double_entry`, `ex_money` — money handling exists
- No Stripe dependency yet
- Swoosh and SMS already follow the behaviour/adapter pattern

### Configuration Pattern
- `config.exs`: compile-time defaults (adapters, operator config)
- `dev.exs`: local dev settings
- `test.exs`: test adapters (Swoosh.Adapters.Test, SMS.Sandbox, Oban manual)
- `runtime.exs`: env-var overrides for prod (SMS/Twilio, Mailer/Postmark)
- Pattern: "safe default in config.exs, prod override in runtime.exs guarded by env var"

### Domain Architecture
- Ash domains: `Haul.Accounts`, `Haul.Operations`, `Haul.Content`
- Domain modules in `lib/haul/{domain}.ex` — `use Ash.Domain` + resource list
- Resources in `lib/haul/{domain}/{resource}.ex`
- Multi-tenancy via AshPostgres `:context` strategy throughout
- Actions are named and intent-driven (`:create_from_online_booking`)

### Relevant Existing Code
- `Haul.Accounts.Company` has `stripe_customer_id` attribute (string, nullable)
- `Haul.Operations.Job` — the booking resource, would receive payment_intent_id
- `Haul.SMS` — behaviour module with `@callback` + runtime adapter dispatch. Good pattern to follow.

### Service Integration Pattern (SMS as precedent)
- `Haul.SMS` defines `@callback send_sms/3`
- `Haul.SMS.Twilio` implements it for production
- `Haul.SMS.Sandbox` implements it for dev/test (logs + process notification)
- Adapter selection: `Application.get_env(:haul, :sms_adapter)`
- Config: `config.exs` sets Sandbox, `runtime.exs` overrides to Twilio when env vars present

### stripity_stripe Library
- Most mature Elixir Stripe client, actively maintained
- Covers full Stripe API: PaymentIntents, Customers, Webhooks, etc.
- Uses `Stripe.API` for HTTP, configurable via `api_key` application config
- Webhook signature verification via `Stripe.Webhook.construct_event/3`
- Test strategy: the library supports configuring a custom HTTP client (mock)

### Future Tickets in Payment Chain
- T-008-02: payment-element (Stripe Elements UI in booking form)
- T-008-03: stripe-webhooks (webhook endpoint + handlers)
- T-008-04: browser-qa
- T-016-01: stripe-subscriptions (SaaS billing, separate story)

## Constraints
- No Stripe keys in source control
- Test must not make live API calls
- Webhook signature verification must be ready (not just PaymentIntents)
- `Haul.Payments` context module — not an Ash domain, a plain context wrapping Stripe SDK
- Company already has `stripe_customer_id` — the Payments module should work with this

## Key Files to Modify
- `mix.exs` — add stripity_stripe dep
- `config/config.exs` — default stripe config
- `config/runtime.exs` — prod stripe env vars
- `config/test.exs` — mock/test config for stripe
- New: `lib/haul/payments.ex` — context module
- New: `test/haul/payments_test.exs` — tests
