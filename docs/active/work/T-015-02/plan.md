# T-015-02 Plan: Onboarding Wizard

## Step 1: Add onboarding_complete to Company

1. Create migration: `priv/repo/migrations/20260309050000_add_onboarding_complete_to_companies.exs`
2. Add `onboarding_complete` attribute to Company resource (boolean, default false, public true)
3. Add `onboarding_complete` to `:update_company` accept list
4. Run migration: `mix ecto.migrate`
5. Verify: existing tests still pass

## Step 2: Add route

1. Add `live "/onboarding", App.OnboardingLive` to `:authenticated` live_session in router.ex
2. Verify: router compiles

## Step 3: Implement OnboardingLive

1. Create `lib/haul_web/live/app/onboarding_live.ex`
2. Mount: load tenant, site_config, services, set step=1, setup upload
3. Implement step navigation: next/back/goto events
4. Implement step 1 (Confirm Info): AshPhoenix.Form for SiteConfig :edit, validate/save events
5. Implement step 2 (Your Site): read-only subdomain display, site URL link
6. Implement step 3 (Services): list current services with count, link to services editor
7. Implement step 4 (Upload Logo): LiveView upload, Storage.put_object, update SiteConfig.logo_url
8. Implement step 5 (Preview): site URL link, "Open in new tab" button
9. Implement step 6 (Go Live): button to set Company.onboarding_complete=true, redirect to /app
10. Implement progress bar component
11. Implement render/1 dispatching to step renders

## Step 4: Write tests

1. Create `test/haul_web/live/app/onboarding_live_test.exs`
2. Test: renders step 1 with pre-filled site config
3. Test: can navigate between steps (next/back)
4. Test: step 1 form validates and saves
5. Test: step 2 shows subdomain
6. Test: step 3 shows services list
7. Test: step 6 go-live sets onboarding_complete and redirects
8. Test: requires authentication (unauthenticated redirects to login)

## Step 5: Verify

1. Run full test suite: `mix test`
2. Verify no regressions in existing tests

## Testing strategy

- **Unit:** Company.onboarding_complete attribute exists and defaults to false
- **Integration:** OnboardingLive renders, navigates steps, saves data, completes onboarding
- **Auth:** Unauthenticated access redirects to login
- **No browser QA** — that's T-015-04
