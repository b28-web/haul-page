# T-013-06 Plan: Browser QA for Content Admin UI

## Prerequisites

1. Verify dev server is running on port 4000
2. Identify login credentials from seed task
3. Verify seeded content exists for default operator

## Step 1: Unauthenticated Redirect

- Navigate to `http://localhost:4000/app`
- Verify redirect to `/app/login`
- Snapshot: login form with email/password fields visible
- **Pass criteria:** Login page rendered with form fields

## Step 2: Authentication

- Fill email and password fields
- Submit login form
- Verify redirect to `/app` dashboard
- Snapshot: dashboard with company name
- **Pass criteria:** Dashboard loads with operator name

## Step 3: Dashboard Verification

- Verify company name displayed
- Verify site URL link present
- Verify sidebar navigation links present
- **Pass criteria:** Dashboard shows operator info and nav

## Step 4: SiteConfig Form

- Navigate to `/app/content/site`
- Snapshot: verify form fields populated (business_name, phone, tagline, etc.)
- **Pass criteria:** Form renders with current values

## Step 5: SiteConfig Edit + Save

- Edit the tagline field to a unique test value
- Submit form
- Verify success flash message appears
- **Pass criteria:** "Site settings updated" flash

## Step 6: Public Page Verification

- Navigate to `http://localhost:4000/`
- Verify the updated tagline appears on the landing page
- **Pass criteria:** Updated tagline visible on public page

## Step 7: Services Page

- Navigate to `/app/content/services`
- Verify services list loads
- Check for service items (title, icon, description)
- **Pass criteria:** Service items rendered in list

## Step 8: Gallery Page

- Navigate to `/app/content/gallery`
- Verify gallery grid loads
- Check for gallery items (images, captions)
- **Pass criteria:** Gallery items rendered in grid

## Step 9: Endorsements Page

- Navigate to `/app/content/endorsements`
- Verify endorsements list loads
- Check for endorsement items (name, stars, quote)
- **Pass criteria:** Endorsement items rendered in list

## Step 10: Mobile Layout

- Resize browser to 375×812
- Navigate to `/app`
- Verify sidebar is collapsed (not visible)
- Look for hamburger menu button
- Click hamburger → verify sidebar slides in
- Navigate via mobile menu
- **Pass criteria:** Hamburger menu works, sidebar collapses

## Step 11: ExUnit Tests

- Run existing admin LiveView tests
- Confirm all pass
- **Pass criteria:** 0 failures across all admin test files

## Step 12: Console Errors

- Check browser console for errors
- **Pass criteria:** No errors at error level (info/debug OK)
