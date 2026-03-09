# T-014-03 Structure: Browser QA for CLI Onboarding

## Files to Create

### `test/haul_web/live/onboarding_qa_test.exs`

Integration test file that:
1. Runs `Haul.Onboarding.run/1` in setup
2. Temporarily sets operator config slug to match the onboarded company
3. Tests all public routes render with correct onboarded content
4. Verifies owner user exists and login page is accessible

**Module:** `HaulWeb.OnboardingQATest`
**Uses:** `HaulWeb.ConnCase, async: false`
**Imports:** `Phoenix.LiveViewTest`

**Setup block:**
- Run onboarding with params: name "Test Hauling", phone "555-0199", email "test@example.com", area "Portland, OR"
- Store original operator config, override slug to "test-hauling"
- on_exit: restore operator config, cleanup tenant schemas
- Return: onboarding result map

**Test cases:**
- `describe "landing page"` — GET /, assert business content
- `describe "scan page"` — live /scan, assert gallery + endorsements
- `describe "booking page"` — live /book, assert form renders
- `describe "admin access"` — live /app/login, assert login form
- `describe "onboarded content quality"` — verify no Lorem Ipsum, professional defaults

## Files to Modify

None. This is a pure test addition.

## Module Boundaries

- Test file depends on: `Haul.Onboarding`, `HaulWeb.ConnCase`, `Phoenix.LiveViewTest`
- No new production code needed
- No changes to existing modules

## File Count

- 1 new file: test
- 0 modified files
