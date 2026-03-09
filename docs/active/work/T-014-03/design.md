# T-014-03 Design: Browser QA for CLI Onboarding

## Problem

Verify that a CLI-onboarded tenant has a fully functional public site with professional default content and owner admin access.

## Approach Options

### Option A: LiveView/Conn Integration Tests

Use `Phoenix.LiveViewTest` and `Phoenix.ConnTest` to verify page rendering after running `Haul.Onboarding.run/1`. Match the pattern used by smoke_test.exs and other browser-qa test files.

**Pros:** Fast, reliable, runs in CI, matches existing patterns, no external dependencies.
**Cons:** Doesn't test actual browser rendering, CSS, or JS interactions.

### Option B: Playwright MCP Browser Tests

Use the Playwright MCP tools to start the dev server, navigate to subdomain URLs, take screenshots.

**Pros:** Tests actual browser rendering, visual verification.
**Cons:** Requires running server, subdomain DNS, flaky, slow, can't run in CI easily.

### Option C: Hybrid — Integration Tests + Playwright Spot Checks

Write comprehensive integration tests (Option A) as the primary verification, with optional Playwright screenshots for visual review.

**Decision: Option A — LiveView/Conn Integration Tests**

This matches the pattern of all other browser-qa tickets in the project (T-002-04, T-003-04, T-005-04, T-006-05). Those tickets all use Phoenix test helpers, not Playwright. The acceptance criteria can be fully verified through HTML content assertions.

## Test Strategy

### Setup
1. Run `Haul.Onboarding.run/1` with known params in test setup
2. Configure the operator slug to match the onboarded company so `ContentHelpers.resolve_tenant()` resolves correctly for the landing page
3. Clean up tenant schemas on exit

### Test Cases

1. **Landing page renders with operator content** — GET `/`, verify business_name, phone, email, service_area appear in HTML, services grid has 6 items.

2. **Scan page loads with gallery and endorsements** — LiveView `/scan`, verify gallery items (4 before/after pairs), endorsements (3 customer quotes), business name, phone.

3. **Booking form loads and accepts input** — LiveView `/book`, verify form renders with required fields.

4. **Login page renders** — LiveView `/app/login`, verify Sign In form with email/password fields.

5. **Owner can authenticate** — Create user with known password via onboarding, then test login flow. However, since onboarding generates a random password, we'll verify: (a) the owner user exists with correct email and role, (b) login page renders, (c) login with wrong credentials shows error.

### Content Assertions

Verify professional content, not Lorem Ipsum:
- Services have real titles: "Junk Removal", "Cleanouts", etc.
- Endorsements have "(Sample)" marker in customer_name
- Gallery items have captions
- SiteConfig has the operator's phone, email, service_area

## Rejected Approaches

- **Playwright MCP**: Overkill for this verification. The other browser-qa tickets that are "done" all use Phoenix test helpers.
- **Testing the mix task directly**: Already covered by `test/mix/tasks/haul/onboard_test.exs`. This ticket tests the rendered output, not the CLI.
- **Subdomain-based routing tests**: TenantResolver tests already cover this. We use the operator slug pattern to keep tests simple.
