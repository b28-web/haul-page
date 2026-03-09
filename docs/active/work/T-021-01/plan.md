# Plan — T-021-01: QA Walkthrough Report

## Step 1: Verify dev server is running

Check if localhost:4000 responds. If not, start it or note limitation.

## Step 2: Take public page screenshots (desktop + mobile)

Use Playwright MCP to capture each public page at both viewports:

1. Resize to 1280×800, navigate to `/`, screenshot → `desktop-landing.png`
2. Resize to 375×812, screenshot → `mobile-landing.png`
3. Resize to 1280×800, navigate to `/scan`, screenshot → `desktop-scan.png`
4. Resize to 375×812, screenshot → `mobile-scan.png`
5. Resize to 1280×800, navigate to `/book`, screenshot → `desktop-booking.png`
6. Resize to 375×812, screenshot → `mobile-booking.png`
7. Resize to 1280×800, navigate to `/scan/qr`, screenshot → `desktop-qr.png`
8. Resize to 1280×800, navigate to `/start`, screenshot → `desktop-chat.png`
9. Resize to 375×812, screenshot → `mobile-chat.png`

## Step 3: Take print media screenshot

Use Playwright to emulate print media on `/`, screenshot → `print-landing.png`

## Step 4: Capture admin pages

1. Resize to 1280×800
2. Navigate to `/app/login`, screenshot → `desktop-login.png`
3. Fill email + password, submit login form
4. Navigate to `/app`, screenshot → `desktop-dashboard.png`
5. Navigate to `/app/content/site`, screenshot → `desktop-site-config.png`
6. Navigate to `/app/content/services`, screenshot → `desktop-services.png`
7. Navigate to `/app/content/gallery`, screenshot → `desktop-gallery.png`
8. Navigate to `/app/settings/billing`, screenshot → `desktop-billing.png`
9. Navigate to `/app/settings/domain`, screenshot → `desktop-domain.png`

## Step 5: Capture signup page

1. Navigate to `/app/signup`, screenshot → `desktop-signup.png`
2. Resize to 375×812, screenshot → `mobile-signup.png`

## Step 6: Write walkthrough.md

Assemble the report following the template from the ticket spec:
- Executive summary from OVERVIEW.md synthesis
- Test results table from all 15 QA ticket results
- Visual walkthrough with screenshot references
- Bugs table consolidated from all QA progress.md files
- Architectural decisions from OVERVIEW.md
- Coverage gaps analysis
- Recommendations

## Step 7: Write progress.md

Track completion of steps 1-6.

## Verification

- walkthrough.md exists with all sections
- All screenshot files referenced in walkthrough.md were captured
- All 15 browser-QA results incorporated
- Report distinguishes tested/untested/unbuilt features
- ExUnit test count and QA ticket count both reported
