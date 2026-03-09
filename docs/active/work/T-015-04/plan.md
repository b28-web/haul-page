# T-015-04 Plan: Browser QA — Self-Service Signup Flow

## Step 1: Write ExUnit integration test

Create `test/haul_web/live/app/signup_flow_test.exs` with:

### 1a. Marketing page verification
- GET `/` on bare domain (host: "haulpage.test")
- Assert marketing page renders (hero text, pricing, features)
- Assert CTA links to `/app/signup`

### 1b. Full signup-to-onboarding flow
- Mount SignupLive at `/app/signup`
- Fill form: name, email, phone, area, password, password_confirmation
- Verify slug preview appears
- Submit form
- Assert `phx-trigger-action` is set (auto-POST to session controller)
- Verify signup created company, tenant, user, content via `Onboarding.signup/1`

### 1c. Onboarding wizard walkthrough (authenticated)
- Use signup result to create authenticated session
- Mount OnboardingLive
- Navigate steps 1-6, verify content at each
- Click "Launch My Site" on step 6
- Verify `onboarding_complete` is set
- Verify redirect to `/app`

### 1d. Tenant site verification
- Configure operator slug to match new tenant
- GET `/` — verify operator content renders (business name, phone, services)

### 1e. Timing measurement
- Log timestamps at key points (signup start, signup complete, onboarding complete)
- Print elapsed time in test output

## Step 2: Run ExUnit tests

```
mix test test/haul_web/live/app/signup_flow_test.exs
```

Fix any failures.

## Step 3: Run full test suite

```
mix test
```

Ensure no regressions.

## Step 4: Playwright MCP browser verification

Start dev server if needed, then:
1. Navigate to `http://localhost:4000` (marketing page)
2. Screenshot marketing page
3. Click "Get Started Free" → signup page
4. Fill signup form, screenshot slug preview
5. Submit → follow through to onboarding
6. Step through wizard, screenshot each step
7. Resize to 375x812 (mobile), screenshot signup form
8. Verify pricing section visually

## Step 5: Write progress.md and review.md

Document results and any issues found.

## Testing Strategy

- **Primary**: ExUnit integration tests (deterministic, CI-friendly)
- **Secondary**: Playwright MCP (visual verification, mobile)
- **Coverage**: Full signup journey, validation, mobile, marketing page
- **Cleanup**: `cleanup_tenants/0` on_exit to drop test schemas
