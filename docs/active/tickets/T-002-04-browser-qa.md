---
id: T-002-04
story: S-002
title: browser-qa
type: task
status: open
priority: high
phase: research
depends_on: [T-002-02]
---

## Context

Automated browser QA for the landing page story. Use Playwright MCP to verify the landing page renders correctly, is navigable, and prints cleanly — without human QA.

## Test Plan

1. `just dev` — ensure dev server is running (singleton, safe to call)
2. Navigate to `http://localhost:4000/`
3. Verify via accessibility snapshot:
   - Hero section: business name, tagline, phone number link (`tel:`)
   - Services grid: 6 service items with titles
   - "Why Hire Us" section present
   - Footer CTA with phone button
4. Resize viewport to 375x812 (mobile) and snapshot again:
   - All sections still present and ordered correctly
   - No horizontal overflow (check page width via `browser_run_code`)
5. Check server logs (`just dev-log`) — no 500 errors, all requests 200

## Acceptance Criteria

- All checks pass when run by a Claude Code agent using Playwright MCP
- Any failures are documented with the snapshot output and server log excerpt
- No manual browser interaction required
