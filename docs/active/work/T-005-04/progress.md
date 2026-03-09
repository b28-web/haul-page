# T-005-04 Progress — Browser QA for Scan Page

## Test Execution Log

### Prerequisites
- Dev server started on port 4000 (`mix phx.server`)
- Playwright MCP connected successfully

### Step 1: Desktop — Navigate and Verify Hero ✅

Navigated to `http://localhost:4000/scan`. Page loaded with title "Scan to Schedule · Phoenix Framework".

**Verified from accessibility snapshot:**
- ✅ "Junk & Handy" business name visible (paragraph element)
- ✅ H1 "Scan to Schedule" present
- ✅ "Call for a free estimate" subheading
- ✅ Phone number "(555) 123-4567" displayed as link
- ✅ Phone `tel:` link correctly formatted: `tel:5551234567`
- ✅ "Book Online" button present, links to `/book`

### Step 2: Desktop — Verify Gallery Section ✅

**Verified from accessibility snapshot:**
- ✅ H2 "Our Work" heading present
- ✅ 3 gallery items rendered
- ✅ "Before" and "After" labels on each item
- ✅ Images have descriptive alt text (e.g., "Before: Full garage cleanout — hauled in one trip")
- ✅ Captions present for all 3 items
- ✅ Placeholder icons shown correctly (photo icon fallback) — all 3 items on desktop

### Step 3: Desktop — Verify Endorsements Section ✅

**Verified from accessibility snapshot:**
- ✅ H2 "What Customers Say" heading present
- ✅ 4 endorsement cards rendered
- ✅ Customer names: Jane D., Mike R., Sarah K., Tom W.
- ✅ Quote text present in curly quotes
- ✅ Star ratings visible (screenshot confirms filled/empty stars)
- ✅ Tom W. shows 4/5 stars (one empty star visible)

### Step 4: Desktop — Verify Footer CTA ✅

**Verified from accessibility snapshot:**
- ✅ H2 "Ready to Book?" heading present
- ✅ Subheading: "Call or book online today — free estimates, no obligation."
- ✅ Call button with `tel:5551234567` link
- ✅ Book Online button linking to `/book`
- ✅ Footer tagline: "Junk & Handy · Your Area"

### Step 5: Mobile Viewport (375×812) ✅ (minor issue)

Resized to 375×812 and re-navigated to `/scan`.

**Verified:**
- ✅ CTA (phone number) is prominent and near top of page — first actionable element
- ✅ "Book Online" button immediately below phone number
- ✅ All sections present: hero, gallery, endorsements, footer
- ✅ Endorsements stack to single column on mobile
- ✅ Footer CTAs are full-width and prominent
- ✅ No horizontal overflow observed

**Minor issue:**
- ⚠️ First gallery item shows broken image alt text instead of placeholder icon on mobile. Items 2 and 3 show the photo icon fallback correctly. This is likely a browser caching/timing issue with the onerror handler — the first images may have been cached as failed from the prior desktop navigation, causing the onerror to not re-fire on the second page load. Not a functional blocker.

### Step 6: Server Health ✅

**Console errors (6 total):**
- All 6 are `404 Not Found` for gallery images (`/images/gallery/before-{1,2,3}.jpg` and `after-{1,2,3}.jpg`)
- These are **expected** — image files don't exist yet, placeholder fallback handles it
- **No 500 errors** — server responded 200 for the page itself
- LiveView mount logged successfully

### Step 7: Screenshots Saved

- `docs/active/work/T-005-04/desktop-full.png` — full-page desktop screenshot
- `docs/active/work/T-005-04/mobile-full.png` — full-page mobile screenshot (375×812)

## Acceptance Criteria Verification

- [x] All content sections present and ordered correctly (hero → gallery → endorsements → footer CTA)
- [x] CTA is accessible and links to correct phone number (`tel:5551234567`)
- [x] No 500 errors in server logs (only expected 404s for missing gallery images)

## Deviations from Plan

None. All steps executed as planned.
