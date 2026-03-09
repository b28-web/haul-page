# T-016-04 Design: Billing Browser QA

## Approach Decision

### Option A: LiveViewTest-based Browser QA (like other QA tickets)

Looking at existing browser QA tests (T-014-03's `onboarding_qa_test.exs`), they use Phoenix.LiveViewTest — not actual Playwright MCP browser automation. This is the established pattern.

**Pros:**
- Fast, deterministic, no external dependencies
- Full access to Ash/Ecto for state setup and verification
- Can simulate the complete flow including webhook effects
- Matches the pattern used by T-014-03

**Cons:**
- Not "real" browser testing — doesn't test JS hooks like ExternalRedirect
- Can't test actual Stripe Checkout redirect behavior

### Option B: Playwright MCP Browser Automation

Use Playwright MCP to drive a real browser against the dev server.

**Pros:**
- Tests actual browser behavior including JS hooks
- Closer to real user experience

**Cons:**
- Requires dev server running
- Sandbox adapter redirects immediately (no Stripe page to test)
- Session management complexity
- Slower, flakier

### Option C: Hybrid — LiveViewTest for flow + Playwright MCP for visual verification

Write LiveViewTest-based tests for the functional flow, then use Playwright MCP interactively to take screenshots and verify layout.

**Decision: Option A — LiveViewTest-based tests**

The existing browser QA pattern (T-014-03) uses LiveViewTest. The billing flow with sandbox adapter can be fully tested this way. The ExternalRedirect JS hook behavior is already implicitly tested by the sandbox adapter returning the correct URL format. Playwright MCP is used for one-time visual verification during development, not as the test runner.

## Test Strategy

### What to test (mapped to ticket test plan):

1. **Billing page renders as authenticated owner on Starter plan** — mount /app/settings/billing, verify plan cards
2. **Current plan (Starter/free) displayed with feature list** — assert "Starter", "Free", "Current Plan"
3. **Tier comparison cards render** — assert all 4 plans with correct pricing and features
4. **Upgrade to Pro flow** — click select_plan pro, verify sandbox creates customer + checkout session
5-6. **Stripe Checkout** — sandbox redirects back immediately; verify the redirect URL is constructed correctly
7. **Return with success message** — mount with session_id param, verify success flash
8. **Plan state after webhook** — simulate webhook by updating company plan, verify billing page reflects new plan
9. **Feature gate: custom domain** — on Starter: domain settings shows upgrade prompt; after upgrade to Pro: shows domain form
10. **Mobile layout** — LiveViewTest can't test CSS, but can verify structure renders (Playwright for visual check)

### Additional coverage beyond ticket test plan:

- Downgrade flow: Pro → Starter with confirmation modal
- Manage Payment Methods button visibility
- Dunning alert display when payment fails
- Authentication redirect for unauthenticated users

### What NOT to test (already covered by billing_live_test.exs):

The existing `billing_live_test.exs` already has 11 tests covering basic rendering and flows. Our QA test should focus on the **end-to-end scenario** — full upgrade lifecycle with feature gate verification — rather than duplicating unit-level assertions.

## Test File Structure

Single test file: `test/haul_web/live/app/billing_qa_test.exs`

Organized as a linear scenario:
1. Setup: create authenticated context (Starter plan)
2. Verify billing page initial state
3. Execute upgrade flow
4. Verify post-upgrade state
5. Verify feature gate activation
6. Verify downgrade flow
7. Verify post-downgrade feature gate deactivation

## Rejected Alternatives

- **Separate Playwright test file**: No — existing pattern uses LiveViewTest
- **Modifying existing billing_live_test.exs**: No — QA tests are separate files by convention
- **Testing with real Stripe test mode**: No — requires API keys, not suitable for CI
