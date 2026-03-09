---
id: T-005-04
story: S-005
title: browser-qa
type: task
status: open
priority: medium
phase: done
depends_on: [T-005-03]
---

## Context

Automated browser QA for the scan page story. Use Playwright MCP to verify the QR-code landing page renders correctly for someone who just scanned a code.

## Test Plan

1. `just dev` — ensure dev server is running
2. Navigate to `http://localhost:4000/scan`
3. Verify via snapshot:
   - Schedule/call CTA prominent and clickable (phone `tel:` link)
   - Before/after gallery section present with images
   - Customer endorsements/testimonials section present
4. Mobile viewport (375x812):
   - CTA is the first actionable element (someone just scanned, wants to act)
   - Gallery items render in a sensible mobile layout
5. Check server logs — no errors

## Acceptance Criteria

- All content sections present and ordered correctly
- CTA is accessible and links to correct phone number
- No 500 errors in server logs
