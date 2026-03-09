# T-002-04 Plan — Browser QA

## Prerequisites

- Dev server running on localhost:4000

## Steps

### Step 1: Ensure dev server is running

- Run `just dev` (idempotent singleton)
- Verify with `curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/`
- Expected: HTTP 200
- If not 200, check `just dev-log` for errors

### Step 2: Desktop accessibility snapshot

- `browser_navigate` to `http://localhost:4000/`
- `browser_snapshot` to capture accessibility tree
- Verify presence of:
  - [ ] H1 containing "Junk Hauling"
  - [ ] Text "& Handyman Services"
  - [ ] Phone number "(555) 123-4567" as a link
  - [ ] "Call for a free estimate" text
  - [ ] H2 "What We Do"
  - [ ] 6 service titles: Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help
  - [ ] H2 "Why Hire Us"
  - [ ] 6 benefit items (same-day, upfront pricing, licensed, cleanup, locally owned, free estimates)
  - [ ] H2 "Ready to Get Started?"
  - [ ] Footer phone CTA button
  - [ ] Email link "hello@junkandhandy.com"
- Document: paste snapshot, annotate pass/fail per item

### Step 3: Mobile viewport snapshot

- `browser_resize` to width=375, height=812
- `browser_snapshot` to capture mobile accessibility tree
- Verify same content items as Step 2
- Verify correct section ordering (hero → services → why-us → footer)
- Document: paste snapshot, annotate pass/fail

### Step 4: Horizontal overflow check

- `browser_run_code` with JS:
  ```javascript
  document.documentElement.scrollWidth <= window.innerWidth
  ```
- Expected: `true` (no horizontal scrollbar)
- If false, measure overflow: `document.documentElement.scrollWidth - window.innerWidth`
- Document result

### Step 5: Server log review

- Run `just dev-log 50` via Bash
- Scan for:
  - [ ] No 500-level errors
  - [ ] Page requests returning 200
  - [ ] No crash reports or exceptions
- Document: relevant log excerpt

### Step 6: Document results

- Write all findings to `progress.md`
- If all checks pass: proceed to review
- If failures found: fix bugs, re-verify, document fixes

## Testing Strategy

All verification is manual-via-agent using Playwright MCP. No automated test files are created. Results are documented in progress.md with full snapshot output for reproducibility.

## Rollback

N/A — this ticket makes no code changes (unless bugs are found and fixed).
