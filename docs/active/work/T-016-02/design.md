# T-016-02 Design: Upgrade Flow

## Decision: Stripe Checkout for Upgrades, API for Downgrades

### Option A: Stripe Checkout for all plan changes
- Upgrade: redirect to Stripe Checkout (hosted payment page)
- Downgrade: also via Stripe (but Checkout doesn't support downgrades)
- **Rejected:** Checkout is for new subscriptions/upgrades only. Downgrades require API calls.

### Option B: Embedded Stripe Elements for everything
- Build custom payment form in-app using Stripe Elements
- Full control over UI
- **Rejected:** Much more complex. Checkout is Stripe's recommended approach for subscription creation. PCI compliance is simpler with Checkout.

### Option C (Chosen): Stripe Checkout for new subscriptions, API for plan changes
- **New subscription (Starter → paid):** Redirect to Stripe Checkout. Customer gets created if needed.
- **Upgrade (paid → higher paid):** Use Stripe Subscription Update to swap the price item. No new checkout needed since payment method is already on file.
- **Downgrade (paid → lower paid or Starter):** Cancel at period end (to Starter) or swap price (to lower paid tier). Confirmation required.
- **Portal:** Link to Stripe Customer Portal for payment methods and invoices.

**Rationale:** This matches Stripe's recommended patterns. Checkout handles the initial payment method collection. Subsequent plan changes use the subscription API since the payment method is already stored.

## Billing Behaviour Extensions

Add 3 new callbacks to `Haul.Billing`:

```elixir
@callback create_checkout_session(params :: map()) :: {:ok, map()} | {:error, term()}
@callback create_portal_session(customer_id :: String.t(), return_url :: String.t()) :: {:ok, map()} | {:error, term()}
@callback update_subscription(subscription_id :: String.t(), params :: map()) :: {:ok, map()} | {:error, term()}
```

### create_checkout_session/1
Params: `%{customer_id, price_id, success_url, cancel_url}`
Returns: `%{id, url}` — the session ID and the Stripe-hosted URL to redirect to.

### create_portal_session/2
Creates a Stripe Billing Portal session. Returns `%{url}`.

### update_subscription/2
Updates an existing subscription (e.g., swap price item for upgrade/downgrade between paid tiers).
Params: `%{price_id: "price_xxx"}` — the new price to switch to.
Returns: `%{id, status, current_period_end, customer}`.

## LiveView Design

### Route: `/app/settings/billing`

### UI Structure
1. **Current Plan Banner** — shows plan name, price, features, billing status
2. **Plan Comparison Grid** — 4-column grid showing all tiers with current plan highlighted
3. **Action Buttons** — per-plan: "Current Plan" (disabled), "Upgrade", or "Downgrade"
4. **Portal Links** — "Manage Payment Methods" and "View Invoices" → Stripe Portal

### State Machine
- `@current_plan` — atom from company.subscription_plan
- `@plans` — from Billing.plans()
- `@loading` — boolean for async operations
- `@confirm_downgrade` — plan atom when showing downgrade confirmation modal

### Event Handlers
- `"select_plan"` with `%{"plan" => plan_id}` — initiates upgrade or shows downgrade confirmation
- `"confirm_downgrade"` — executes the downgrade
- `"cancel_downgrade"` — dismisses confirmation
- `"manage_billing"` — creates portal session and redirects

### Upgrade Flow (in LiveView)
1. User clicks "Upgrade to Pro" on a plan card
2. `handle_event("select_plan", ...)` fires
3. Server ensures Stripe Customer exists (create if needed, persist stripe_customer_id)
4. If upgrading FROM Starter (no subscription): create Checkout Session, redirect to Stripe
5. If upgrading FROM another paid plan (has subscription): update subscription price via API, show success flash
6. On Checkout return: success_url includes `?session_id=...` — mount checks for this and shows success flash

### Downgrade Flow (in LiveView)
1. User clicks "Downgrade to Starter"
2. Modal appears: "Your plan will change to Starter at the end of your current billing period on [date]."
3. User confirms → server calls cancel_subscription (cancel_at_period_end)
4. Flash: "Your plan will downgrade at the end of your billing period."
5. For paid-to-paid downgrade: update subscription price (takes effect at next renewal)

### External Redirect Pattern
LiveView can't do external redirects from handle_event. Options:
- **Option 1:** Return a JS command that sets `window.location`
- **Option 2:** Use a controller endpoint that creates the session and redirects
- **Chosen: Option 1** — Use `push_event` to push a "redirect" event to a JS hook that does `window.location.href = url`. This keeps all logic in the LiveView. Simple JS hook, 5 lines.

## Sandbox Adapter Design

For dev/test, the sandbox adapter needs to handle the 3 new callbacks:
- `create_checkout_session/1` — return a fake URL (e.g., `"/app/settings/billing?session_id=cs_sandbox_123"`)
- `create_portal_session/2` — return a fake URL
- `update_subscription/2` — return updated subscription map

The sandbox checkout URL should point back to the app so dev/test flows work without Stripe.

## Admin Layout Changes

Add a "Billing" link under Settings in the sidebar. When on `/app/settings/*`, show submenu:
- Settings (general)
- Billing

Actually, simpler: just add the billing route. The Settings link already exists. We can either:
1. Make Settings a submenu like Content
2. Just add `/app/settings/billing` as its own sidebar link

**Decision:** Add "Billing" as a separate top-level sidebar link with a credit-card icon. It's important enough to be top-level, and the Settings section is currently a stub anyway.

## Success URL Handling

When Stripe redirects back after checkout:
- URL: `/app/settings/billing?session_id={CHECKOUT_SESSION_ID}`
- On mount, if `session_id` param is present:
  1. Show success flash
  2. Refresh company data to pick up any webhook-driven updates
  3. The actual subscription activation will be handled by webhooks (T-016-03), but we can optimistically update the UI

For now (before T-016-03 webhooks), we'll update the company's subscription_plan in the success handler since we know which plan they selected. T-016-03 will add the webhook-based confirmation.

## Testing Strategy

- Unit tests for new Billing callbacks (sandbox adapter)
- LiveView tests:
  - Renders plan comparison with current plan highlighted
  - Upgrade click creates checkout session (sandbox returns local URL)
  - Downgrade shows confirmation modal
  - Downgrade confirmation calls cancel_subscription
  - Portal link creates portal session
  - Success URL param shows success flash
