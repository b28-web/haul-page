# T-016-03 Research: Billing Webhooks

## Existing Webhook Infrastructure

### WebhookController (`lib/haul_web/controllers/webhook_controller.ex`)
- Single action `stripe/2` at POST `/webhooks/stripe`
- Extracts raw body from `conn.assigns[:raw_body]` (CacheBodyReader plug)
- Signature verification via `Haul.Payments.verify_webhook_signature/3`
- Handles: `payment_intent.succeeded`, `payment_intent.payment_failed`
- Unknown events return 200 OK — graceful passthrough
- Uses sandbox adapter in test (just `Jason.decode`)

### Router (`lib/haul_web/router.ex`)
- Webhook scope: `scope "/webhooks"` with `:api` pipeline (no CSRF)
- Single route: `post "/stripe", WebhookController, :stripe`
- Ticket asks for separate `/webhooks/stripe/billing` endpoint

### Payments Module (`lib/haul/payments.ex`)
- `verify_webhook_signature/3` dispatches to adapter
- Stripe adapter wraps `Stripe.Webhook.construct_event/3`
- Sandbox adapter does `Jason.decode(payload)` — no real signature check

### Config
- `stripe_webhook_secret` in runtime.exs from `STRIPE_WEBHOOK_SECRET` env var
- Ticket implies a separate billing webhook secret may be needed
- Single signing secret currently shared

## Billing Domain

### Company Resource (`lib/haul/accounts/company.ex`)
- `subscription_plan`: atom, default `:starter`, one_of [:starter, :pro, :business, :dedicated]
- `stripe_customer_id`: nullable string
- `stripe_subscription_id`: nullable string
- No dunning fields exist yet
- `update_company` action accepts all billing fields

### Billing Module (`lib/haul/billing.ex`)
- Adapter pattern: Sandbox (dev/test) / Stripe (prod)
- Feature gates: `can?/2` checks plan features
- Plans: starter (free), pro ($29), business ($79), dedicated ($149)
- Price IDs from config: `:stripe_price_pro`, etc.
- No reverse lookup: price_id → plan atom

### BillingLive (`lib/haul_web/live/app/billing_live.ex`)
- Displays current plan, plan cards, upgrade/downgrade
- No dunning warning banner currently
- Updates company plan directly on downgrade — webhook should be source of truth

## Event Mapping

The ticket requires handling these Stripe events:

| Event | Stripe Object | Key Fields |
|---|---|---|
| `checkout.session.completed` | Session | customer, subscription, metadata |
| `customer.subscription.updated` | Subscription | id, customer, items[].price.id, status |
| `customer.subscription.deleted` | Subscription | id, customer |
| `invoice.payment_failed` | Invoice | customer, subscription, attempt_count |
| `invoice.paid` | Invoice | customer, subscription |

## Company Lookup Strategy

- `checkout.session.completed`: metadata should include `company_id` (set in BillingLive)
- Subscription events: `customer` field → lookup by `stripe_customer_id`
- Invoice events: `customer` field → lookup by `stripe_customer_id`

## Dunning Requirements

- Failed payment → Stripe retries 3x automatically (Stripe handles retry schedule)
- After final failure → 7-day grace period → downgrade to Starter
- Grace period: features still work, admin UI shows warning banner
- Need: `dunning_started_at` timestamp on Company
- Need: Oban scheduled job or cron to check grace period expiry
- `invoice.paid` clears dunning state

## Price ID → Plan Mapping

Currently Billing has `price_id(:pro)` etc. but no reverse. Need a function:
```
plan_for_price_id("price_xxx") → :pro
```
To map subscription item price IDs back to plan atoms in webhook handlers.

## Email for Payment Failure

- `invoice.payment_failed` → send operator email
- Existing pattern: Oban workers in `lib/haul/workers/`
- Mailer: `Haul.Mailer` with Swoosh
- Can create a simple email directly or via new worker

## Test Infrastructure

- `HaulWeb.WebhookControllerTest` — existing pattern with `webhook_payload/3` and `post_webhook/2`
- Creates Company, tenant, Job in setup
- Sandbox adapter doesn't verify signatures — just parses JSON
- Tests verify Company state changes via `Ash.get`

## Key Constraints

1. Ticket says separate `/webhooks/stripe/billing` endpoint
2. Same raw body caching mechanism works (already in endpoint)
3. May need separate webhook secret config key for billing webhooks
4. Idempotent: replaying same event must be safe
5. All events logged with Company ID
