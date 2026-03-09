# Design — T-021-01: QA Walkthrough Report

## Decision: Report-only ticket, no code changes

This ticket produces documentation artifacts (walkthrough.md + screenshots), not code. The design decisions are about report structure, screenshot strategy, and information architecture.

## Approach: Screenshots + synthesized report

### Option A: Playwright MCP screenshots only
Take fresh screenshots of every page. Report references them.
- Pro: current visual state, consistent capture
- Con: dev server must be running, screenshots gitignored so only useful locally

### Option B: Synthesize from existing QA artifacts only
Compile progress.md/review.md data into a report without new screenshots.
- Pro: no runtime dependency, all data already gathered
- Con: misses current visual state, developer wants to see the product

### Option C (chosen): Both — fresh screenshots + QA synthesis
Take Playwright screenshots for every implemented page AND incorporate all QA ticket results. Report structure follows the ticket spec exactly.

**Rationale:** The ticket explicitly requires fresh screenshots AND QA result incorporation. The developer wants a visual walkthrough document they can read to understand what was built.

## Screenshot strategy

**Viewports:**
- Desktop: 1280×800 (matches ticket spec)
- Mobile: 375×812 (matches ticket spec)

**Naming convention:** `{viewport}-{page}.png`
- `desktop-landing.png`, `mobile-landing.png`
- `desktop-scan.png`, `mobile-scan.png`
- `desktop-booking.png`, `mobile-booking.png`
- `desktop-qr.png`
- `desktop-chat.png`, `mobile-chat.png`
- `desktop-dashboard.png`
- `desktop-site-config.png`
- `desktop-services.png`
- `desktop-gallery.png`
- `desktop-billing.png`
- `desktop-domain.png`
- `desktop-signup.png`, `mobile-signup.png`
- `desktop-login.png`
- `print-landing.png` (print media emulation)

**Auth flow for admin pages:**
1. Navigate to `/app/login`
2. Fill credentials (admin@example.com / Password123!)
3. Submit form → authenticated session
4. Navigate to each admin route

**Prerequisite:** Dev server running on localhost:4000 with seeded data.

## Report structure

Follow the ticket spec template exactly:
1. Executive summary — one paragraph
2. Test results summary — table by area with ExUnit + Playwright columns
3. Visual walkthrough — section per page with screenshots and notes
4. Bugs found during QA — consolidated table
5. Architectural decisions — bullet list from OVERVIEW.md
6. Coverage gaps — untested areas
7. Recommendations — prioritized next steps

## Rejected alternatives

- **HTML report with embedded images:** Markdown is sufficient, images referenced by path. Consistent with all other project docs.
- **Automated screenshot comparison:** No baseline images exist, this is a first-pass walkthrough not regression testing.
- **Video recording:** Playwright supports it but markdown can't embed video. Screenshots are more reviewable.
