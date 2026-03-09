# T-006-05 Design: Browser QA for Content Domain

## Goal

Verify that after seeding, content-driven pages render seeded data correctly — not hardcoded fallback data. This is a QA-only ticket: no code changes, just browser verification.

## Approach Options

### Option A: Playwright MCP manual walkthrough

Use Playwright MCP tools interactively to navigate pages, take snapshots, and verify content in the accessibility tree. Document findings in progress.md.

**Pros:** Matches established pattern (T-002-04, T-003-04, T-005-04). Fast to execute. No test code to maintain.
**Cons:** Not automated/repeatable. Manual verification each time.

### Option B: Write ExUnit browser tests with Wallaby/Hound

Add a browser testing library and write automated tests.

**Pros:** Repeatable, part of CI.
**Cons:** Heavy dependency addition. Out of scope for this ticket. Existing ExUnit tests already verify content rendering via `Phoenix.ConnTest` and `Phoenix.LiveViewTest`.

### Option C: Playwright MCP walkthrough + screenshot artifacts

Same as Option A but save screenshots as evidence.

**Pros:** Visual record. Matches T-003-04 pattern.
**Cons:** Screenshots take disk space, may not render in all review contexts.

## Decision: Option A — Playwright MCP walkthrough

Rationale:
- Matches the pattern of T-002-04, T-003-04, T-005-04 (all browser-qa tickets used this approach)
- ExUnit integration tests (135 passing) already verify content rendering programmatically
- This ticket's value is visual/behavioral confirmation, not automated regression
- No code changes needed — pure QA verification

## Test Strategy

### Prerequisites
1. Verify dev server running at localhost:4000
2. Verify tenant provisioned and content seeded
3. If not seeded, run `mix haul.seed_content`

### Test Steps

**Step 1: Landing page (`/`) — Services grid**
- Navigate to `/`
- Verify business name "Junk & Handy" in hero
- Verify phone "(555) 123-4567" present
- Verify all 6 service titles appear: Junk Removal, Furniture Pickup, Appliance Hauling, Yard Waste, Construction Debris, Estate Cleanout
- Verify service descriptions are non-empty

**Step 2: Scan page (`/scan`) — Gallery**
- Navigate to `/scan`
- Verify gallery section exists
- Verify gallery items have captions from seed data
- Verify before/after image pairs present (may show placeholder if URLs 404)

**Step 3: Scan page (`/scan`) — Endorsements**
- Verify endorsement section exists
- Verify customer names: Jane D., Mike R., Sarah K., Tom B.
- Verify star ratings rendered (filled/empty star icons)
- Verify quote text from seed data visible

**Step 4: Booking page (`/book`) — SiteConfig**
- Navigate to `/book`
- Verify business name "Junk & Handy" visible
- Verify phone "(555) 123-4567" present

**Step 5: Markdown pages — N/A**
- No routes exist for `/about` or `/faq`
- Document as not-yet-implemented (future ticket)
- Page resources exist in DB but are not served

**Step 6: Server health**
- Check dev log for 500 errors or template warnings during test session

**Step 7: Mobile viewport (375×812)**
- Resize to mobile dimensions
- Verify landing page and scan page render without horizontal overflow

## Acceptance Criteria Mapping

| Criterion | Test step | Expected |
|-----------|-----------|----------|
| Seeded content renders on all public pages | Steps 1-4 | Service titles, endorsements, gallery items from Ash resources |
| Markdown pages produce valid HTML | Step 5 | N/A — no route exists yet |
| No 500 errors or template warnings | Step 6 | Clean server logs |
