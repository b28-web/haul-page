# T-002-04 Design — Browser QA

## Approach

This is a QA-only ticket. The "implementation" is running Playwright MCP checks against the live dev server and documenting results. No code changes unless bugs are discovered.

## Options Considered

### Option A: Playwright MCP interactive checks (chosen)

Run Playwright MCP tools directly from the agent session:
1. Start dev server via `just dev`
2. Navigate to localhost:4000
3. Take accessibility snapshots at desktop and mobile viewports
4. Verify expected content via snapshot text matching
5. Check for horizontal overflow via JS evaluation
6. Review server logs for errors

**Pros:** Matches ticket requirements exactly. Uses available MCP tools. Results documented in work artifacts.
**Cons:** Not repeatable as automated tests (but that's not the ticket's scope).

### Option B: Write ExUnit browser tests with Wallaby

Write permanent integration tests using Wallaby/ChromeDriver.

**Rejected:** Out of scope. Ticket explicitly says "run by a Claude Code agent using Playwright MCP." Wallaby tests could be a separate ticket if needed.

### Option C: HTML unit tests only (controller tests)

Use `Phoenix.ConnTest` to assert HTML structure without a real browser.

**Rejected:** Already covered by existing tests (11 tests passing per OVERVIEW). This ticket specifically requires browser-level verification including viewport responsiveness.

## Verification Strategy

### Desktop Check (default viewport ~1280x720)
- Navigate to `http://localhost:4000/`
- `browser_snapshot` → verify accessibility tree contains:
  - "Junk Hauling" heading
  - "& Handyman Services" text
  - Phone number link with `tel:` href
  - "What We Do" heading with 6 service titles
  - "Why Hire Us" heading
  - "Ready to Get Started?" heading
  - Email link with `mailto:` href

### Mobile Check (375x812)
- `browser_resize` to 375x812
- `browser_snapshot` → verify same content present
- `browser_run_code` → check `document.documentElement.scrollWidth <= 375` (no horizontal overflow)

### Server Health
- `just dev-log 50` → scan for 500 errors or crashes
- All page requests should return 200

### Failure Handling

If any check fails:
- Document the failure in progress.md with the full snapshot/log output
- Assess whether it's a rendering bug (needs code fix) or a test issue
- If code fix needed, make minimal fix and re-verify
- If test assumption wrong, adjust check and document why

## Decision

Proceed with Option A. Run checks in order: ensure server up → desktop snapshot → mobile snapshot → overflow check → log review. Document all results in progress.md.
