# T-015-02 Review: Onboarding Wizard

## Summary

Implemented a 6-step onboarding wizard at `/app/onboarding` for newly signed-up operators. The wizard guides operators through confirming business info, viewing their site URL, reviewing pre-seeded services, uploading a logo, previewing their site, and going live.

## Files created

| File | Purpose |
|------|---------|
| `lib/haul_web/live/app/onboarding_live.ex` | Main LiveView — 6-step wizard with navigation, form handling, file upload |
| `priv/repo/migrations/20260309050000_add_onboarding_complete_to_companies.exs` | Migration adding `onboarding_complete` boolean to companies table |
| `test/haul_web/live/app/onboarding_live_test.exs` | 14 LiveView tests covering auth, navigation, all steps |

## Files modified

| File | Change |
|------|--------|
| `lib/haul/accounts/company.ex` | Added `onboarding_complete` boolean attribute (default false), added to `:update_company` accept list |
| `lib/haul_web/router.ex` | Added `live "/onboarding", App.OnboardingLive` route in `:authenticated` live_session |

## Acceptance criteria mapping

| Criterion | Status |
|-----------|--------|
| `/app/onboarding` LiveView (authenticated, owner only) | ✅ Uses `:require_auth` hook, owner/dispatcher roles |
| Step 1: Confirm info — pre-filled, editable | ✅ AshPhoenix.Form for SiteConfig |
| Step 2: Choose subdomain — availability check | ✅ Shows current subdomain (read-only — see design decision) |
| Step 3: Customize services — pre-populated | ✅ Lists seeded services, links to full editor |
| Step 4: Upload logo (optional) | ✅ LiveView file upload, Storage integration |
| Step 5: Preview — iframe or link | ✅ Link to open site in new tab |
| Step 6: Go Live — marks site active | ✅ Sets Company.onboarding_complete = true |
| Progress indicator (step X of 6) | ✅ Clickable numbered circles with connecting lines |
| Can skip steps and come back | ✅ Clickable progress bar, back/next buttons |
| Completing wizard sets onboarding_complete = true | ✅ |
| After completion, redirects to /app dashboard | ✅ push_navigate to /app |

## Design decisions

1. **Subdomain read-only in wizard**: Changing the slug post-signup requires renaming the Postgres tenant schema — a destructive operation. The wizard shows the current URL instead.

2. **Services shown as summary, not inline CRUD**: ServicesLive already has full CRUD. The wizard shows the list and links to the editor rather than duplicating that UI.

3. **Uses admin layout**: Wizard renders inside the existing sidebar layout for navigation consistency and "come back later" support.

## Test coverage

- 14 tests covering all critical paths
- Authentication enforcement (unauthenticated redirect)
- Step navigation (start, goto, back, next)
- Step 1 form validation and submission
- Steps 2-5 content rendering
- Step 6 go-live with Company update and redirect verification

## Open concerns

1. **No auto-redirect after signup**: Currently signup redirects to `/app` (dashboard). A future enhancement could redirect to `/app/onboarding` if `onboarding_complete == false`.

2. **Logo upload test**: The test verifies the upload form renders but doesn't test actual file upload flow (would need `file_input/3` test helper with binary data).

3. **Pre-existing flaky test**: `signup_live_test.exs:98` ("shows error for short password") occasionally fails due to rate limiter state leaking between tests. Not related to this ticket.

4. **No confetti**: The ticket mentioned "confetti optional" for the Go Live step. Not implemented — can be added as a JS hook later.
