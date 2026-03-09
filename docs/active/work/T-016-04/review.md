# T-016-04 Review: Billing Browser QA

## Summary

Created end-to-end browser QA test suite for the subscription billing flow. 16 tests verify the complete upgrade/downgrade lifecycle, feature gate activation, dunning alerts, and authentication.

## Files Changed

| File | Action | Purpose |
|------|--------|---------|
| `test/haul_web/live/app/billing_qa_test.exs` | Created | 16 QA tests for billing flow |

No production code changes.

## Test Coverage

### Tests Written (16 total)

**Billing page initial state (5 tests):**
- All 4 tier comparison cards render (Starter, Pro, Business, Dedicated)
- Starter shown as current plan with Free pricing
- Upgrade buttons for Pro, Business, Dedicated; no downgrade button
- Feature labels displayed (SMS Notifications, Custom Domain, Payment Collection, Crew App)
- Manage Payment Methods hidden without Stripe customer

**Upgrade flow (4 tests):**
- Clicking "Upgrade to Pro" creates sandbox customer and triggers checkout
- Returning with `session_id` param shows success flash
- After plan update to Pro, billing page reflects new plan with correct buttons
- Upgrading existing subscription updates plan immediately

**Feature gate verification (2 tests):**
- Starter plan: domain settings shows "Upgrade Plan" prompt, no domain form
- Pro plan: domain settings shows "Add Custom Domain" form, no upgrade prompt

**Downgrade flow (3 tests):**
- Clicking downgrade shows confirmation modal
- Confirming downgrade changes plan to Starter
- After downgrade, domain settings reverts to upgrade prompt

**Dunning alert (1 test):**
- Payment issue warning displayed when `dunning_started_at` is set

**Authentication (1 test):**
- Unauthenticated users redirected to login

### Acceptance Criteria Coverage

| Criterion | Status | Tests |
|-----------|--------|-------|
| Full upgrade flow verified | ✅ | Upgrade flow tests (4) |
| Plan changes reflected immediately in UI | ✅ | "billing page reflects Pro", "upgrading existing subscription" |
| Feature gates activate on upgrade | ✅ | Feature gate tests (2) + downgrade revert test |

### What's NOT tested (and why)

- **Stripe Checkout page rendering** (steps 5-6 in ticket): Sandbox adapter returns immediately to app. Real Stripe test mode requires API keys and isn't suitable for CI.
- **Mobile viewport CSS layout** (step 10): LiveViewTest can't verify CSS rendering. The HTML structure renders correctly; visual layout verification would require Playwright MCP against a running server.
- **Stripe billing portal**: Portal redirect is tested via sandbox adapter in existing `billing_live_test.exs`.

## Open Concerns

None. All tests pass (16/16, 0 failures). The billing flow is well-covered between this QA suite and the existing `billing_live_test.exs` (11 tests). Combined coverage: 27 tests across the billing feature.
