# T-016-04 Structure: Billing Browser QA

## Files

### New Files

| File | Purpose |
|------|---------|
| `test/haul_web/live/app/billing_qa_test.exs` | Browser QA test — end-to-end billing flow verification |

### No Modified Files

This is a QA-only ticket. No production code changes.

## Test File Structure

```elixir
defmodule HaulWeb.App.BillingQATest do
  use HaulWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  # Setup: create company + user on Starter plan, cleanup tenants on exit

  describe "billing page initial state" do
    # Test: renders billing page with all 4 plan cards
    # Test: shows Starter as current plan with Free pricing
    # Test: shows upgrade buttons for Pro, Business, Dedicated
    # Test: shows feature labels (SMS, Custom Domain, etc.)
    # Test: does not show Manage Payment Methods (no stripe customer yet)
  end

  describe "upgrade flow" do
    # Test: clicking upgrade to Pro creates sandbox customer and triggers redirect
    # Test: returning with session_id shows success flash
    # Test: after plan update to Pro, billing page shows Pro as current
    # Test: Pro plan shows downgrade to Starter and upgrade to Business/Dedicated
  end

  describe "feature gate verification" do
    # Test: on Starter, domain settings shows upgrade prompt
    # Test: after upgrade to Pro, domain settings shows domain form (not upgrade prompt)
  end

  describe "downgrade flow" do
    # Test: clicking downgrade to Starter shows confirmation modal
    # Test: confirming downgrade changes plan back to Starter
    # Test: after downgrade, domain settings shows upgrade prompt again
  end

  describe "dunning alert" do
    # Test: when dunning_started_at is set, billing page shows payment issue warning
  end
end
```

## Module Dependencies

```
BillingQATest
  ├── HaulWeb.ConnCase (auth helpers)
  ├── Phoenix.LiveViewTest (LiveView assertions)
  ├── Haul.Accounts.Company (plan state)
  ├── Haul.Billing (plan definitions, feature gates)
  └── Ash (changeset updates for state setup)
```

## Helper Functions

- `authenticated_conn/2` — reuse pattern from billing_live_test.exs
- `set_company_plan/2` — reuse pattern from billing_live_test.exs
- Both are local to the test module (not shared helpers)
