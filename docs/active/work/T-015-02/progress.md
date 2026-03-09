# T-015-02 Progress: Onboarding Wizard

## Completed

### Step 1: Add onboarding_complete to Company ✓
- Created migration `20260309050000_add_onboarding_complete_to_companies.exs`
- Added `onboarding_complete` boolean attribute to Company resource (default: false)
- Added to `:update_company` accept list
- Migration ran successfully

### Step 2: Add route ✓
- Added `live "/onboarding", App.OnboardingLive` to `:authenticated` live_session in router.ex

### Step 3: Implement OnboardingLive ✓
- Created `lib/haul_web/live/app/onboarding_live.ex` (~300 lines)
- 6-step wizard with step navigation (next/back/goto)
- Step 1: Confirm Info — AshPhoenix.Form for SiteConfig, validates and saves
- Step 2: Your Site — shows subdomain URL (read-only), link to preview
- Step 3: Services — lists pre-seeded services, links to full editor
- Step 4: Upload Logo — LiveView file upload → Storage → SiteConfig.logo_url
- Step 5: Preview — site URL with "Open in New Tab" link
- Step 6: Go Live — sets Company.onboarding_complete = true, redirects to /app
- Progress bar with clickable step indicators

### Step 4: Write tests ✓
- Created `test/haul_web/live/app/onboarding_live_test.exs` (14 tests)
- Auth: redirects unauthenticated, renders for authenticated
- Navigation: starts at step 1, goto, back, next
- Step 1: shows fields, validates, saves and advances
- Step 2: shows subdomain
- Step 3: shows services list
- Step 4: shows upload form
- Step 5: shows preview link
- Step 6: go live sets onboarding_complete, redirects

### Step 5: Verify ✓
- All 14 onboarding tests pass
- Full suite: 360 tests, 1 pre-existing flaky failure (signup rate limiter state leak)
- No regressions from my changes

## Deviations from plan
- None. Plan followed as written.
