# Progress — T-021-01: QA Walkthrough Report

## Completed steps

### Step 1: Dev server verification ✅
Started Phoenix dev server on localhost:4000. Confirmed healthz endpoint returns 200.

### Step 2: Public page screenshots ✅
Captured 11 public page screenshots (desktop + mobile):
- `desktop-landing.png` / `mobile-landing.png` — platform marketing page
- `desktop-scan.png` / `mobile-scan.png` — scan page with gallery/endorsements
- `desktop-booking.png` / `mobile-booking.png` — booking form
- `desktop-chat.png` / `mobile-chat.png` — chat onboarding interface
- `desktop-signup.png` / `mobile-signup.png` — operator signup form
- `desktop-login.png` — admin login page

### Step 3: Print media screenshot ✅
Captured `print-landing.png` with Playwright print media emulation. Note: this shows the platform marketing page, not the operator tenant landing (which has the tear-off coupon strip but requires subdomain access).

### Step 4: Admin page screenshots ✅
Authenticated as joe@joeandsons.com (joe-sons-hauling tenant). Required:
1. Setting a known password via Bcrypt (no default dev password existed)
2. Generating a JWT token via Ash.read_one with sign_in_with_password
3. POSTing token + tenant to /app/session via form submission

Captured 6 admin page screenshots:
- `desktop-dashboard.png` — dashboard with sidebar nav, welcome message
- `desktop-site-config.png` — site settings form (business info, location, appearance)
- `desktop-services.png` — services CRUD list
- `desktop-gallery.png` — gallery manager
- `desktop-billing.png` — subscription billing tiers
- `desktop-domain.png` — custom domain settings

### Step 5: Signup page ✅
Captured in Step 2 (desktop + mobile).

### Step 6: Walkthrough report ✅
Wrote `walkthrough.md` with all sections per ticket spec:
- Executive summary
- Test results table (15 QA tickets, 742 ExUnit tests)
- Visual walkthrough (13 page sections with screenshots)
- Bugs table (9 bugs, 2 fixed in code, 4 pre-existing, 3 minor)
- Architectural decisions (16 decisions)
- Coverage gaps (11 areas analyzed)
- Recommendations (10 items)

### Step 7: Test verification ✅
Full test suite: 742 tests, 0 failures (1 excluded). 186.6 seconds.

## Deviations from plan

1. **QR screenshot skipped** — `/scan/qr` triggers an SVG file download, not a rendered page. Noted in walkthrough.
2. **Operator tenant landing not captured** — The `/` route on localhost shows the platform marketing page, not a tenant-specific operator page (which requires subdomain routing). The tenant landing page with tear-off coupons is verified by ExUnit tests but cannot be browser-screenshotted on localhost.
3. **Admin auth required manual token generation** — No default dev user exists. Had to set a password via Bcrypt and generate a JWT token programmatically to authenticate the Playwright session.
4. **Endorsements admin not separately captured** — Covered in T-013-06 QA but not separately screenshotted. The sidebar shows it as a nav item in the Content submenu.

## Screenshot inventory

18 PNG files in `docs/active/work/T-021-01/`:
- 7 desktop public: landing, scan, booking, chat, signup, login, qr (skipped)
- 4 mobile public: landing, scan, booking, chat, signup
- 6 desktop admin: dashboard, site-config, services, gallery, billing, domain
- 1 print: landing (print media emulation)
