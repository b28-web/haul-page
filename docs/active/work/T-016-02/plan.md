# T-016-02 Plan: Upgrade Flow

## Step 1: Extend Billing Behaviour + Adapters

### Changes
1. Add 3 new callbacks to `lib/haul/billing.ex`: `create_checkout_session/1`, `create_portal_session/2`, `update_subscription/2`
2. Add dispatch functions
3. Implement in `lib/haul/billing/stripe.ex` using stripity_stripe
4. Implement in `lib/haul/billing/sandbox.ex` with sandbox responses
5. Add `feature_label/1` helper to Billing for UI display names

### Tests
- Add sandbox callback tests to `test/haul/billing_test.exs`

### Verification
- `mix test test/haul/billing_test.exs` passes

## Step 2: Add JS Hook for External Redirect

### Changes
- Check `assets/js/app.js` for existing Hooks object
- Add `ExternalRedirect` hook that listens for "redirect" event

### Verification
- Code compiles, no syntax errors

## Step 3: Add Route + Sidebar Link

### Changes
1. Add `live "/settings/billing", App.BillingLive` to router's authenticated live_session
2. Add "Billing" link in admin layout sidebar

### Verification
- Router compiles without conflicts

## Step 4: Create BillingLive LiveView

### Changes
- Create `lib/haul_web/live/app/billing_live.ex`
- Mount: load plans, current plan, check for session_id param
- Render: plan comparison cards, current plan highlighted, action buttons
- handle_event for select_plan, confirm_downgrade, cancel_downgrade, manage_billing
- handle_params for checkout return (session_id)
- Helper: ensure_customer, plan_rank, format_price

### Verification
- Module compiles

## Step 5: Write LiveView Tests

### Changes
- Create `test/haul_web/live/app/billing_live_test.exs`
- Test: renders billing page with all plan cards
- Test: current plan highlighted
- Test: upgrade from starter works (sandbox checkout URL)
- Test: downgrade shows confirmation modal
- Test: confirm downgrade cancels subscription
- Test: manage billing creates portal session
- Test: unauthenticated redirects to login

### Verification
- `mix test test/haul_web/live/app/billing_live_test.exs` passes
- `mix test` full suite passes

## Step 6: Final Verification

### Checks
- `mix compile --warnings-as-errors` clean
- `mix test` all passing
- Manual review of the upgrade/downgrade flow logic
- Confirm sandbox adapter enables full dev/test without Stripe keys

## Commit Strategy

- Single commit after all steps pass: "T-016-02: billing settings LiveView with upgrade/downgrade flow"
