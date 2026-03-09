# T-014-03 Review: Browser QA for CLI Onboarding

## Summary

Created end-to-end browser QA tests that verify a CLI-onboarded operator gets a fully functional site. The tests run `Haul.Onboarding.run/1` then assert all public pages render correctly with the seeded content.

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `test/haul_web/live/onboarding_qa_test.exs` | ~135 | 10 integration tests covering all acceptance criteria |

## Files Modified

None.

## Test Coverage

**10 new tests, all passing. Full suite: 325 tests, 0 failures.**

| Test | What it verifies |
|------|-----------------|
| Landing page content | Phone, email, service_area, "What We Do" heading |
| Landing page services | Default services render (Junk Removal, Cleanouts) |
| Scan page gallery/endorsements | "Our Work" section, "What Customers Say" section, phone |
| Scan page gallery captions | Before/After labels present |
| Scan page endorsement quotes | "(Sample)" marker in customer names |
| Booking form | Form element renders at `/book` |
| Login page | Sign In heading, Email/Password fields at `/app/login` |
| Owner user role | User email and :owner role correct |
| Content quantity | 6 services, 4 gallery items, 3 endorsements |
| SiteConfig values | phone, email, service_area match onboarding params |

## Acceptance Criteria Verification

- **CLI-provisioned tenant has a fully functional public site** — All public routes (/, /scan, /book, /app/login) render successfully after onboarding.
- **Default content renders professionally (not Lorem Ipsum)** — Services have real titles, endorsements have customer quotes, gallery has captions.
- **Owner can access admin UI** — Login page renders; owner user exists with correct role and email.

## Open Concerns

1. **business_name not updated by onboarding**: `Haul.Onboarding.update_site_config/2` sets phone, email, and service_area but does NOT set business_name. The SiteConfig retains "Your Business Name" from the defaults pack. The Company record has the correct name ("Test Hauling"), but this doesn't propagate to SiteConfig.business_name. This means the landing page hero and scan page header show "Your Business Name" instead of the operator's actual business name. **Recommendation:** Add `business_name` to the `update_site_config` call in `Haul.Onboarding.run/1`.

2. **Owner login flow not fully testable**: Onboarding generates a random password via `crypto.strong_rand_bytes/24`, which is printed to stdout but not captured in the return value. Tests can verify the owner user exists and the login page renders, but cannot test a successful login without either: (a) returning the password in the result, or (b) resetting the password in the test.

3. **No responsive layout test**: The ticket mentions "Resize to mobile" but Phoenix.LiveViewTest doesn't support viewport testing. This would require Playwright MCP for visual verification.
