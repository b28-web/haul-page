# T-005-04 Design — Browser QA for Scan Page

## Objective

Verify the scan page renders correctly in a real browser using Playwright MCP. This is a QA-only ticket — no application code changes. The deliverable is a browser-verified confirmation that the scan page meets acceptance criteria.

## Approach Options

### Option A: Playwright MCP Interactive Testing
Run Playwright MCP commands to navigate to the scan page, take snapshots, verify content sections, and test mobile viewport. This is interactive — each check produces immediate visual/structural feedback.

**Pros:** Direct browser verification, catches rendering issues unit tests miss, tests real CSS/layout.
**Cons:** Requires dev server running, non-deterministic (depends on server state).

### Option B: Add Wallaby/Hound Integration Tests
Write permanent browser integration tests in Elixir using Wallaby or Hound.

**Pros:** Repeatable, runs in CI.
**Cons:** Overkill for this ticket — adds a testing dependency for what the ticket asks (Playwright MCP verification). T-002-04 (landing page QA) established the pattern of using Playwright MCP directly.

### Option C: Screenshot-based Regression
Take Playwright screenshots and store as reference images for visual regression.

**Pros:** Catches visual regressions.
**Cons:** High maintenance, brittle across environments, not what the ticket asks for.

## Decision: Option A — Playwright MCP Interactive Testing

Matches the ticket's explicit instruction ("Use Playwright MCP to verify"). Consistent with T-002-04 pattern. No new dependencies.

## Test Plan (Detailed)

### Desktop Viewport (default)

1. **Navigate to `/scan`** — verify 200 response, page loads
2. **Hero section verification:**
   - Business name "Junk & Handy" visible
   - H1 "Scan to Schedule" present
   - Phone number displayed and is a `tel:` link
   - "Book Online" button present
3. **Gallery section:**
   - "Our Work" heading present
   - Before/After labels visible
   - Gallery items render (with placeholder icons since images don't exist)
4. **Endorsements section:**
   - "What Customers Say" heading present
   - Customer names visible (Jane D., etc.)
   - Star rating icons present
5. **Footer CTA:**
   - "Ready to Book?" heading
   - Call and Book Online buttons present
   - Footer tagline with business name

### Mobile Viewport (375×812)

6. **Resize to 375×812** (iPhone X dimension)
7. **CTA prominence** — phone number / call button should be the first actionable element
8. **Layout sanity** — no horizontal overflow, gallery items stack sensibly
9. **All sections still present** — mobile doesn't hide content

### Server Health

10. **Check server logs** — no 500 errors during page load

## Expected Findings

- Gallery images will show placeholder icons (expected — no real images yet)
- "Book Online" links to `/book` which returns 404 (expected — booking form not built yet)
- All content sections should render with correct dark theme styling
- Phone number should be clickable `tel:` link

## Non-Goals

- Performance testing
- Cross-browser testing (Playwright default browser only)
- Accessibility audit (separate concern)
- Testing QR code generation endpoint (covered by unit tests)
