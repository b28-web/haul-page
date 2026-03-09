# T-016-02 Research: Upgrade Flow

## Ticket Summary

Build `/app/settings/billing` LiveView where operators can view their current plan, upgrade via Stripe Checkout, downgrade with end-of-period handling, and access Stripe Customer Portal for payment methods and invoices.

## Existing Billing Infrastructure

### Haul.Billing module (`lib/haul/billing.ex`)
- Behaviour-based with pluggable adapters (Sandbox for dev/test, Stripe for prod)
- **Callbacks:** `create_customer/1`, `create_subscription/2`, `cancel_subscription/1`
- **Feature gates:** `can?/2`, `plan_features/1` — pure functions checking company.subscription_plan
- **Plan catalog:** `plans/0` returns 4 plans with id, name, price_cents, features
- **Price IDs:** `price_id/1` reads from config (`:stripe_price_pro`, etc.)
- No Stripe Checkout session creation yet
- No Stripe Customer Portal session creation yet

### Billing Adapters
- `Haul.Billing.Stripe` — wraps stripity_stripe for Customer/Subscription CRUD
- `Haul.Billing.Sandbox` — canned responses with process notification for test assertions
- Both implement the 3 callbacks above

### Company Resource (`lib/haul/accounts/company.ex`)
- Has `subscription_plan` atom enum (:starter, :pro, :business, :dedicated), default :starter
- Has `stripe_customer_id` (nullable string)
- Has `stripe_subscription_id` (nullable string)
- `:update_company` action accepts all billing fields

### Configuration
- `config.exs` sets billing_adapter to Sandbox, price IDs to empty strings
- `runtime.exs` switches to Stripe adapter when STRIPE_SECRET_KEY is set
- Price IDs come from STRIPE_PRICE_PRO, STRIPE_PRICE_BUSINESS, STRIPE_PRICE_DEDICATED env vars

### Router (`lib/haul_web/router.ex`)
- Authenticated routes under `/app` in `:authenticated` live_session
- Uses `AuthHooks.require_auth` on_mount
- Layout: `{HaulWeb.Layouts, :admin}`
- No billing route exists yet — `/app/settings` points to DashboardLive placeholder

### Admin Layout (`lib/haul_web/components/layouts/admin.html.heex`)
- Sidebar with Dashboard, Content (submenu), Bookings, Settings links
- No billing/subscription link in sidebar yet
- Settings currently points to `/app/settings` (stub)

### Auth Hooks (`lib/haul_web/live/auth_hooks.ex`)
- Assigns `@current_user`, `@current_company`, `@current_path`
- These are available in all authenticated LiveViews

### Stripe Webhook Controller (`lib/haul_web/controllers/webhook_controller.ex`)
- Handles `payment_intent.succeeded` and `payment_intent.payment_failed`
- Does NOT handle subscription lifecycle events yet (that's T-016-03)

## LiveView Patterns in Codebase

### General Pattern
- `use HaulWeb, :live_view`
- `mount/3` assigns data, `render/1` uses `~H` sigil
- `handle_event/3` for user actions
- Forms via `to_form/2` with `phx-change` / `phx-submit`

### Test Pattern
- `use HaulWeb.ConnCase, async: false` (tenant-creating tests)
- `create_authenticated_context/1` → returns %{company, tenant, user, token}
- `log_in_user/2` → sets session with token + tenant
- `import Phoenix.LiveViewTest` for `live/2`, `render_click/3`, etc.
- `on_exit(fn -> cleanup_tenants() end)` for cleanup

## Missing Capabilities Needed

1. **Stripe Checkout session creation** — not in Billing behaviour yet. Need `create_checkout_session/1` that takes customer_id, price_id, success/cancel URLs.
2. **Stripe Customer Portal session** — not in Billing behaviour yet. Need `create_portal_session/2` that takes customer_id and return_url.
3. **Ensure customer exists before checkout** — need to create Stripe Customer if company has no stripe_customer_id, then persist it via update_company.
4. **Downgrade logic** — Stripe's `cancel_at_period_end` vs immediate cancel. Current `cancel_subscription/1` does immediate cancel. May need `update_subscription/2` to switch price, or schedule cancellation.

## Stripe Checkout Flow

1. User clicks "Upgrade to Pro"
2. Server creates Stripe Customer (if needed), persists stripe_customer_id
3. Server creates Stripe Checkout Session with mode: "subscription", customer, price, success/cancel URLs
4. Server returns redirect URL to client
5. Client redirects to Stripe-hosted checkout
6. On success, Stripe redirects back to success_url
7. Webhook (T-016-03) will handle subscription activation — but for MVP, we can update plan on checkout success return

## Downgrade Flow

1. User clicks "Downgrade to Starter"
2. Confirmation dialog: "Your plan will change at the end of your billing period"
3. Server calls Stripe to cancel subscription at period end
4. UI shows "Downgrading to Starter on [date]"

## Key Constraints

- No JS framework — all server-rendered via LiveView
- Stripe Checkout is an external redirect (not embedded)
- LiveView can't do external redirects directly — need to use `redirect(external: url)` or a controller endpoint
- stripity_stripe has `Stripe.Checkout.Session.create/1` and `Stripe.BillingPortal.Session.create/1`
- Sandbox adapter needs matching functions for dev/test

## File Impact Assessment

| File | Change |
|------|--------|
| `lib/haul/billing.ex` | Add checkout_session + portal_session callbacks |
| `lib/haul/billing/stripe.ex` | Implement checkout + portal via stripity_stripe |
| `lib/haul/billing/sandbox.ex` | Sandbox implementations |
| `lib/haul_web/live/app/billing_live.ex` | NEW — main billing settings LiveView |
| `lib/haul_web/router.ex` | Add `/app/settings/billing` route |
| `lib/haul_web/components/layouts/admin.html.heex` | Add billing link under Settings |
| `test/haul_web/live/app/billing_live_test.exs` | NEW — LiveView tests |
| `test/haul/billing_test.exs` | Add tests for new callbacks |
