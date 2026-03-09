# T-016-04 Plan: Billing Browser QA

## Steps

### Step 1: Create test file with setup

Create `test/haul_web/live/app/billing_qa_test.exs` with:
- `use HaulWeb.ConnCase, async: false`
- Setup block: `on_exit(fn -> cleanup_tenants() end)`
- Helper: `authenticated_conn/2` and `set_company_plan/2`

### Step 2: Initial state tests

Write tests for billing page initial state:
1. Renders all 4 plan cards (Starter, Pro, Business, Dedicated)
2. Shows Starter as current with "Free" pricing
3. Shows correct upgrade buttons
4. Shows feature labels
5. No "Manage Payment Methods" button without stripe customer

### Step 3: Upgrade flow tests

Write tests for upgrade lifecycle:
1. Click "Upgrade to Pro" — sandbox creates customer, triggers checkout
2. Mount with `session_id` param — success flash shown
3. After updating plan to Pro — billing page reflects new plan
4. Pro user sees correct buttons (downgrade Starter, current Pro, upgrade Business/Dedicated)

### Step 4: Feature gate tests

Write tests verifying feature gates activate/deactivate:
1. Starter plan → domain settings shows "Upgrade Plan" prompt
2. Pro plan → domain settings shows "Add Custom Domain" form

### Step 5: Downgrade flow tests

Write tests for downgrade:
1. Pro → click downgrade to Starter → confirmation modal appears
2. Confirm downgrade → plan changes to Starter
3. After downgrade → domain settings shows upgrade prompt again

### Step 6: Dunning alert test

Write test verifying dunning warning:
1. Set `dunning_started_at` on company
2. Navigate to billing → yellow payment issue warning shown

### Step 7: Run tests and verify

Run `mix test test/haul_web/live/app/billing_qa_test.exs` and fix any failures.

## Verification Criteria

- All tests pass
- Tests cover ticket acceptance criteria:
  - Full upgrade flow verified ✓ (Steps 3-4)
  - Plan changes reflected in UI ✓ (Step 3)
  - Feature gates activate on upgrade ✓ (Step 4)
- No production code changes needed
