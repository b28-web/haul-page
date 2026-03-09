# T-016-01 Research: Stripe Subscriptions

## Ticket Summary

Add subscription billing infrastructure: 4-tier plan model (starter/pro/business/dedicated), Stripe Customer/Subscription linking on Company, and a feature gate module `Haul.Billing.can?/2`.

## Existing Codebase

### Company Resource (`lib/haul/accounts/company.ex`)

The Company resource lives in public schema (not tenant-scoped). Current subscription-related attributes:

- `subscription_plan` — atom, default `:free`, constrained to `[:free, :pro]`
- `stripe_customer_id` — nullable string (already exists)

**Missing from AC:**
- `stripe_subscription_id` — not yet added
- Plan enum needs changing: `:free` → `:starter`, add `:business` and `:dedicated`

Actions:
- `create_company` — accepts subscription_plan
- `update_company` — accepts subscription_plan, stripe_customer_id

### Stripe Infrastructure (T-008-01 completed)

**Dependency:** `stripity_stripe ~> 3.2` in mix.exs

**Adapter pattern:**
- `Haul.Payments` — behaviour module with `create_payment_intent/1`, `retrieve_payment_intent/1`, `verify_webhook_signature/3`
- `Haul.Payments.Stripe` — production adapter wrapping `Stripe.PaymentIntent.*`
- `Haul.Payments.Sandbox` — dev/test adapter with canned responses and process notification for test assertions

**Config:**
- `config :haul, :payments_adapter` — selects adapter (Sandbox in dev/test, Stripe in prod)
- `config :stripity_stripe, api_key:` — API key (empty in dev, from env in prod)
- Webhook route: `POST /webhooks/stripe` → `WebhookController.stripe/2`

**Pattern to follow:** The Payments module uses a simple behaviour + adapter dispatch via `Application.get_env`. The Billing module should follow the same pattern for subscription operations.

### Migration Patterns

Public schema migrations in `priv/repo/migrations/`. Company table changes go here since Company is public-schema.

Existing Company migration created the table with `subscription_plan :text, default: "free"` and `stripe_customer_id :text`. New migration needs to:
1. Add `stripe_subscription_id` column
2. Update `subscription_plan` values (`:free` → `:starter`)

### Test Patterns

- `test/support/conn_case.ex` has `create_authenticated_context/1` that creates Company + provisions tenant + creates User
- Sandbox adapter uses `Process.put(:payments_sandbox_pid, self())` for test message assertions
- Integration tests use `async: false`

### Accounts Domain

`lib/haul/accounts.ex` — simple Ash domain with Company, User, Token resources. No custom domain functions. The Billing module will be a separate context, not part of Accounts.

### Feature Gate Consumers

No existing feature gate checks. Once `Haul.Billing.can?/2` is created, it will be consumed by:
- SMS notification sending (pro+) — Oban workers in `lib/haul/notifications/`
- Custom domain setup (pro+) — tenant routing
- Payment collection (business+) — payment LiveView
- Crew app access (business+) — future

These consumers exist but don't gate on plan yet. This ticket creates the gate; wiring it in is later work.

## Constraints

- `stripity_stripe ~> 3.2` supports `Stripe.Customer`, `Stripe.Subscription`, `Stripe.Product`, `Stripe.Price` APIs
- Starter plan is free — no Stripe product needed, just internal tracking
- Stripe Products/Prices should be created via Mix task (idempotent), not auto-created at runtime
- Company is public-schema, so migration goes in `priv/repo/migrations/`
- The plan enum change from `:free` to `:starter` is a data migration concern

## Open Questions

1. Should the Mix task for creating Stripe products be a new task or extend existing `mix haul.seed`? → Likely new task (`mix haul.stripe_setup`) since it's a one-time Stripe API operation, not content seeding.
2. Should existing `:free` plan values be migrated to `:starter` in the DB migration? → Yes, in the same migration.
3. Does the Billing module need its own adapter pattern like Payments? → Yes, for testability. Subscription creation/customer creation should go through a billing adapter.
