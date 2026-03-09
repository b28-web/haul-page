# T-005-04 Plan — Browser QA for Scan Page

## Prerequisites

1. Verify dev server is running on port 4000
2. If not, start it with `mix phx.server`

## Step 1: Desktop — Navigate and Verify Hero

- Navigate Playwright to `http://localhost:4000/scan`
- Take accessibility snapshot
- **Verify:**
  - Page loads (no error page)
  - "Junk & Handy" business name visible
  - "Scan to Schedule" heading present
  - Phone number "(555) 123-4567" displayed
  - Phone number is a clickable `tel:` link
  - "Book Online" button present

## Step 2: Desktop — Verify Gallery Section

- Scroll/snapshot gallery area
- **Verify:**
  - "Our Work" heading present
  - "Before" and "After" labels visible
  - Gallery items render (placeholder icons acceptable since images don't exist)
  - Captions present

## Step 3: Desktop — Verify Endorsements Section

- Snapshot endorsements area
- **Verify:**
  - "What Customers Say" heading present
  - Customer names visible (Jane D., Mike R., Sarah L., Tom W.)
  - Star rating icons rendered
  - Quote text present

## Step 4: Desktop — Verify Footer CTA

- Snapshot footer area
- **Verify:**
  - "Ready to Book?" heading present
  - Call button with phone link
  - Book Online button
  - Footer tagline with business name and service area

## Step 5: Mobile Viewport — Responsive Layout

- Resize browser to 375×812 (iPhone X)
  - Navigate to `/scan` again to ensure clean mobile render
- Take snapshot
- **Verify:**
  - CTA (phone number / call button) is prominent and near top
  - No horizontal scroll / overflow
  - All sections still present (hero, gallery, endorsements, footer)
  - Gallery items render in mobile-appropriate layout

## Step 6: Server Health Check

- Check dev server logs for any 500 errors during the test session
- Note any warnings or errors

## Step 7: Document Results

- Write all findings to progress.md
- Flag any bugs or issues found
- Note expected behaviors (missing images, /book 404) vs unexpected issues

## Verification Criteria

All acceptance criteria from the ticket:
- [ ] All content sections present and ordered correctly
- [ ] CTA is accessible and links to correct phone number
- [ ] No 500 errors in server logs
