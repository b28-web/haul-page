# T-016-02 Progress: Upgrade Flow

## Completed Steps

### Step 1: Extend Billing Behaviour + Adapters
- Added 3 new callbacks: `create_checkout_session/1`, `create_portal_session/2`, `update_subscription/2`
- Added dispatch functions to `Haul.Billing`
- Added `feature_label/1` helper for UI display names
- Implemented all 3 in `Haul.Billing.Stripe` using stripity_stripe SDK
- Implemented all 3 in `Haul.Billing.Sandbox` with sandbox responses and test notifications
- Added unit tests for all new callbacks + feature_label

### Step 2: JS Hook for External Redirect
- Added `ExternalRedirect` hook to `assets/js/app.js`
- Listens for `"redirect"` event and sets `window.location.href`
- Registered in LiveSocket hooks object

### Step 3: Route + Sidebar Link
- Added `live "/settings/billing", App.BillingLive` to authenticated live_session in router
- Added "Billing" sidebar link with `hero-credit-card` icon in admin layout

### Step 4: Create BillingLive LiveView
- Created `lib/haul_web/live/app/billing_live.ex`
- Plan comparison grid with 4 cards (Starter, Pro, Business, Dedicated)
- Current plan highlighted with border styling
- Upgrade from Starter: creates Stripe Customer → Checkout Session → external redirect
- Upgrade from paid: updates subscription via API → immediate plan change
- Downgrade: confirmation modal → cancel subscription or update to lower tier
- Manage Payment Methods: creates Stripe Portal session → external redirect
- Checkout return: detects `session_id` param, shows success flash
- Helper functions: ensure_customer, plan_rank, format_price

### Step 5: Tests
- Created `test/haul_web/live/app/billing_live_test.exs` with 12 tests
- Added 5 tests to `test/haul/billing_test.exs` for new callbacks
- Added test price IDs to `config/test.exs`
- All 41 billing tests pass
- Full suite: 415 tests, 0 failures

### Step 6: Verification
- `mix compile` clean (no warnings)
- `mix test` — 415 tests, 0 failures

## Deviations from Plan

- Added test price IDs to `config/test.exs` (not in original plan, but necessary for tests to work)
- Sandbox `create_checkout_session` returns a URL pointing back to the app's billing page with session_id appended (enables dev/test flow without Stripe)
- Sandbox `create_portal_session` returns the return_url directly (no external redirect in dev/test)
