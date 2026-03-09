---
id: T-020-05
story: S-020
title: browser-qa
type: task
status: open
priority: high
phase: ready
depends_on: [T-020-03]
---

## Context

Playwright MCP verification of the full AI-powered onboarding pipeline: conversation → content generation → preview → live site. This is the end-to-end magic moment.

## Test Plan

1. Navigate to `/start` — complete a full onboarding conversation providing all business info
2. When profile is complete, click "Create my site"
3. Verify provisioning progress indicator (or loading state)
4. Verify preview appears with generated content: landing page with business name, generated tagline, service descriptions, "why hire us" points
5. Request a change in chat: "Change the tagline" — verify preview updates
6. Click "Looks good — go live!"
7. Navigate to the new operator's subdomain URL
8. Verify landing page renders with generated content (not placeholders)
9. Verify `/scan` page has default gallery and endorsements
10. Verify `/book` form works on the new tenant
11. Mobile: repeat the confirmation and preview steps

## Acceptance Criteria

- Full chat-to-live-site pipeline verified via Playwright MCP
- Generated content looks professional on the public pages
- Edit-in-chat updates are reflected in preview
- New tenant site is fully functional
