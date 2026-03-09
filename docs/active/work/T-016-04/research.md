# T-016-04 Research: Billing Browser QA

## Ticket Scope

Playwright MCP verification of the subscription billing flow: upgrade UI, Stripe Checkout redirect, plan state changes, and feature gates.

## Existing Implementation

### Billing LiveView (`lib/haul_web/live/app/billing_live.ex`)

- Route: `/app/settings/billing` (router line 66, inside authenticated `/app` scope)
- Renders 4 plan cards in a grid: Starter (Free), Pro ($29/mo), Business ($79/mo), Dedicated ($149/mo)
- Current plan highlighted with `border-foreground ring-1 ring-foreground`
- Upgrade buttons: `phx-click="select_plan"` with `phx-value-plan` attribute
- Downgrade shows confirmation modal before executing
- Checkout return: detects `session_id` URL param, shows success flash
- Dunning alert: yellow warning banner when `dunning_started_at` is set
- Manage Payment Methods button: only shown when `stripe_customer_id` is set
- Uses `ExternalRedirect` JS hook for Stripe redirect

### Billing Context (`lib/haul/billing.ex`)

- Adapter pattern: Sandbox (dev/test) or Stripe (prod)
- Feature gates: `can?(company, feature)` — map-based per plan
  - Starter: no features
  - Pro: `:sms_notifications`, `:custom_domain`
  - Business: `:sms_notifications`, `:custom_domain`, `:payment_collection`, `:crew_app`
  - Dedicated: same as Business
- `plans()` returns list of plan structs with id, name, price_cents, features
- `price_id(plan)` maps atom to Stripe Price ID (test config: `price_test_pro`, etc.)

### Sandbox Adapter (`lib/haul/billing/sandbox.ex`)

- `create_customer/1`: returns `{:ok, "cus_sandbox_<rand>"}`
- `create_checkout_session/1`: returns `{:ok, %{url: success_url <> "?session_id=cs_sandbox_<rand>", id: ...}}`
- `create_subscription/2`: returns `{:ok, %{id: "sub_sandbox_<rand>", ...}}`
- `update_subscription/2`: returns `{:ok, %{id: sub_id}}`
- `cancel_subscription/1`: returns `{:ok, %{id: sub_id}}`
- `create_portal_session/2`: returns `{:ok, %{url: return_url <> "?portal=1"}}`
- Sends process messages for assertion: `{:customer_created, id, company}`, etc.

### Webhook Controller (`lib/haul_web/controllers/billing_webhook_controller.ex`)

- Route: POST `/webhooks/stripe/billing` (router line 79)
- Handles: checkout.session.completed, customer.subscription.updated, customer.subscription.deleted, invoice.payment_failed, invoice.paid
- Company lookup via metadata `company_id` or `stripe_customer_id`
- Updates `subscription_plan`, `stripe_customer_id`, `stripe_subscription_id`

### Domain Settings LiveView (`lib/haul_web/live/app/domain_settings_live.ex`)

- Feature gate: `Billing.can?(company, :custom_domain)` on mount (line 10)
- If false: shows upgrade prompt with link to `/app/settings/billing`
- If true: shows domain management UI (add, verify DNS, remove)
- This is the feature gate verification target from ticket test plan step 9

### Authentication Setup (test/support/conn_case.ex)

- `create_authenticated_context/1`: creates company + tenant + user + token
- `log_in_user/2`: sets session with user_token + tenant
- `cleanup_tenants/0`: drops all tenant_ schemas

### Existing Test Coverage (`test/haul_web/live/app/billing_live_test.exs`)

- 232 lines, 11 tests covering:
  - Plan card rendering (Starter/Pro/Business/Dedicated)
  - Pricing display (Free, $29/mo, $79/mo, $149/mo)
  - Feature labels (SMS, Custom Domain, etc.)
  - Upgrade from starter → checkout redirect (sandbox)
  - Upgrade with existing subscription → plan update
  - Downgrade modal flow (show, confirm, cancel)
  - Manage billing button visibility
  - Checkout return flash
  - Auth redirect

### Router Context

```
/app scope (authenticated):
  /app/settings/billing -> BillingLive
  /app/settings/domains -> DomainSettingsLive
```

## Sandbox Behavior for Browser QA

The sandbox adapter returns URLs that redirect back to the app (success_url with session_id param). This means the full checkout flow CAN be tested end-to-end in test mode — clicking "Upgrade to Pro" will:
1. Create sandbox customer
2. Create sandbox checkout session
3. Push redirect to success_url?session_id=cs_sandbox_xxx
4. Handle params shows success flash

However, there's a critical detail: the sandbox checkout URL points back to the app, so there's no actual Stripe Checkout page to interact with. The test plan steps 5-6 (verify Stripe Checkout page, complete test payment with 4242 card) cannot be verified with sandbox — these are production Stripe test mode scenarios.

For browser QA, we can verify:
1. Billing page renders with all plan cards ✓
2. Current plan (Starter) displayed ✓
3. Tier comparison cards render ✓
4. Click "Upgrade to Pro" triggers redirect event ✓
5-6. Stripe Checkout steps — sandbox returns to app immediately
7. Redirect back with success flash ✓
8. Plan updates after webhook simulation ✓
9. Feature gate on domain settings ✓
10. Mobile viewport test ✓

## Key Files

| File | Role |
|------|------|
| `lib/haul_web/live/app/billing_live.ex` | Billing UI, plan cards, upgrade/downgrade |
| `lib/haul/billing.ex` | Feature gates, plan definitions, adapter dispatch |
| `lib/haul/billing/sandbox.ex` | Test-mode adapter |
| `lib/haul_web/live/app/domain_settings_live.ex` | Feature gate consumer (custom domain) |
| `test/haul_web/live/app/billing_live_test.exs` | Existing unit tests |
| `test/support/conn_case.ex` | Auth helpers |
| `lib/haul_web/router.ex` | Route definitions |

## Constraints

- Browser QA uses Playwright MCP (not LiveViewTest)
- Sandbox adapter means no real Stripe Checkout page
- The ExternalRedirect JS hook pushes redirect — Playwright can intercept this
- Tests must run against dev server (port 4000) or test server
- Need authenticated session — login via `/app/login` form
