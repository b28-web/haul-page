# T-016-02 Structure: Upgrade Flow

## Files Modified

### `lib/haul/billing.ex`
- Add 3 new `@callback` declarations: `create_checkout_session/1`, `create_portal_session/2`, `update_subscription/2`
- Add 3 new dispatch functions that delegate to adapter
- Add `@feature_labels` map for human-readable feature names (used in UI)

### `lib/haul/billing/stripe.ex`
- Implement `create_checkout_session/1` using `Stripe.Checkout.Session.create/1`
- Implement `create_portal_session/2` using `Stripe.BillingPortal.Session.create/1`
- Implement `update_subscription/2` using `Stripe.Subscription.update/2`

### `lib/haul/billing/sandbox.ex`
- Implement `create_checkout_session/1` — returns sandbox URL pointing to app
- Implement `create_portal_session/2` — returns sandbox URL
- Implement `update_subscription/2` — returns updated map with new price

### `lib/haul_web/router.ex`
- Add `live "/settings/billing", App.BillingLive` inside authenticated live_session

### `lib/haul_web/components/layouts/admin.html.heex`
- Add "Billing" sidebar link with `hero-credit-card` icon after Settings

## Files Created

### `lib/haul_web/live/app/billing_live.ex`
New LiveView module. Structure:

```
mount/3
  - Read company.subscription_plan
  - Load plans from Billing.plans()
  - Check for ?session_id param (checkout return)
  - If session_id present, show success flash + update plan

render/1
  - Current plan banner (name, price, status)
  - Plan comparison grid (4 cards)
  - Each card: plan name, price, feature list, action button
  - Current plan card highlighted with border
  - Downgrade confirmation modal (conditionally rendered)

handle_event("select_plan", %{"plan" => plan}, socket)
  - If target plan == current plan → no-op
  - If target plan is higher (upgrade):
    - Ensure Stripe Customer exists
    - If no subscription (from Starter): create_checkout_session → push redirect
    - If has subscription: update_subscription → flash + update assigns
  - If target plan is lower (downgrade):
    - Set @confirm_downgrade to target plan

handle_event("confirm_downgrade", _, socket)
  - If downgrading to Starter: cancel_subscription
  - If downgrading to lower paid tier: update_subscription
  - Clear @confirm_downgrade, update assigns, flash

handle_event("cancel_downgrade", _, socket)
  - Clear @confirm_downgrade

handle_event("manage_billing", _, socket)
  - create_portal_session → push redirect

handle_params/3
  - Check for session_id query param on navigation
```

Helper functions:
- `ensure_customer/1` — creates Stripe Customer if needed, updates company
- `plan_rank/1` — returns numeric rank for plan comparison (starter=0, pro=1, etc.)
- `format_price/1` — converts cents to dollar string

### `test/haul_web/live/app/billing_live_test.exs`
Tests using ConnCase + LiveViewTest:
- Renders billing page with plan cards
- Shows current plan as highlighted
- Upgrade from starter triggers checkout (sandbox URL)
- Downgrade shows confirmation
- Confirm downgrade calls cancel
- Portal link works
- Unauthenticated access redirects to login

### `test/haul/billing_test.exs` (modified)
Add tests for new sandbox callbacks:
- create_checkout_session returns url
- create_portal_session returns url
- update_subscription returns updated map

## Module Boundaries

- `Haul.Billing` — pure business logic + adapter dispatch. No web concerns.
- `BillingLive` — orchestrates the flow. Calls Billing functions, manages UI state.
- `Haul.Accounts.Company` — updated via Ash actions when stripe fields change.
- No new Ash resources needed.

## JS Hook for External Redirect

Add a small hook in `assets/js/app.js` (or inline):
```js
Hooks.ExternalRedirect = {
  mounted() {
    this.handleEvent("redirect", ({url}) => {
      window.location.href = url
    })
  }
}
```

This lets the LiveView push an external URL redirect from handle_event.

## Data Flow

```
User clicks Upgrade
  → handle_event("select_plan")
  → ensure_customer(socket) — creates Stripe Customer if needed
  → Billing.create_checkout_session(%{customer_id, price_id, urls})
  → push_event(socket, "redirect", %{url: checkout_url})
  → Browser redirects to Stripe Checkout
  → Stripe redirects to /app/settings/billing?session_id=xxx
  → handle_params detects session_id
  → Update company subscription_plan
  → Show success flash

User clicks Downgrade
  → handle_event("select_plan") detects downgrade
  → assign(:confirm_downgrade, target_plan)
  → Modal renders
  → User clicks Confirm
  → handle_event("confirm_downgrade")
  → Billing.cancel_subscription() or update_subscription()
  → Update company subscription_plan
  → Flash success
```
