# T-003-04 Design — Browser QA for Booking Form

## Approach

Interactive Playwright MCP testing against the live dev server. This follows the established pattern from T-002-04 and T-005-04.

## Options Considered

### Option A: Playwright MCP interactive tests (CHOSEN)
- Use Playwright MCP tools to navigate, snapshot, fill forms, submit, and verify
- Tests run against `just dev` server on localhost:4000
- Results documented in progress.md with screenshots
- **Pros:** Matches prior QA pattern, tests real browser rendering, catches CSS/JS issues
- **Cons:** Requires dev server running, creates real DB records

### Option B: Extend existing LiveView tests
- Add more test cases to `booking_live_test.exs`
- **Pros:** Automated, repeatable, CI-friendly
- **Cons:** Doesn't test actual browser rendering, CSS, or JS. Unit tests already exist with good coverage (20 tests). This ticket specifically calls for browser QA.

### Option C: Playwright test scripts (automated)
- Write `.spec.ts` test files
- **Pros:** Fully automated, repeatable
- **Cons:** Requires Node.js test runner setup, over-engineered for this ticket's scope

**Decision:** Option A. The ticket explicitly asks for Playwright MCP verification, matching the pattern set by T-002-04 and T-005-04. The existing 20 unit tests cover logic; this ticket covers visual/browser behavior.

## Test Sequence

1. **Page load & field verification** — Navigate to `/book`, snapshot, verify all form fields present
2. **Validation test** — Submit empty form, verify error messages appear for required fields
3. **Happy path** — Fill valid data, submit, verify confirmation screen
4. **Reset test** — Click "Submit Another Request", verify form resets
5. **Mobile viewport** — Resize to 375×812, verify form renders without overflow
6. **Server health** — No 500 errors during any step

## Bug Handling

If bugs are found during QA:
- Document in progress.md with screenshots
- Fix if the fix is trivial and within scope (e.g., missing assign)
- Log as blocker in review.md if fix is complex or out of scope

## Artifacts

- Screenshots saved to `docs/active/work/T-003-04/`
- Results documented in progress.md
- Final assessment in review.md
