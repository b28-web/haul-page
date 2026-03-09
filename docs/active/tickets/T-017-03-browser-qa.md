---
id: T-017-03
story: S-017
title: browser-qa
type: task
status: open
priority: low
phase: done
depends_on: [T-017-02]
---

## Context

Playwright MCP verification of the custom domain flow in the admin UI.

## Test Plan

1. Navigate to `/app/settings/domain` as Pro-tier operator
2. Verify current subdomain URL displayed
3. Enter a custom domain in the form
4. Verify CNAME instructions appear with correct target
5. Click "Verify DNS" — verify status update (pending/verified depending on DNS state)
6. As a Starter-tier operator: navigate to same page — verify upgrade prompt shown instead of domain form
7. Mobile: verify domain settings form is usable

## Acceptance Criteria

- Domain settings UI renders correctly for Pro+ and shows gate for Starter
- CNAME instructions are clear and correct
- Status updates are visible
