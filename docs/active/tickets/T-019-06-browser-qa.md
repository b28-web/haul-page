---
id: T-019-06
story: S-019
title: browser-qa
type: task
status: open
priority: high
phase: ready
depends_on: [T-019-02, T-019-05]
---

## Context

Playwright MCP verification of the conversational onboarding chat. This is the signature UX of the product — it must feel natural, responsive, and produce a real site.

## Test Plan

1. Navigate to `/start` — verify chat UI loads with welcome message from AI
2. Verify dark theme, message bubbles layout, text input with send button
3. Type a message ("I run a junk removal business called Joe's Hauling in Portland") — verify AI responds
4. Verify streaming: response tokens appear progressively (not all at once)
5. Verify profile panel: business name and service area should populate after first message
6. Continue conversation with additional info (phone, email, services)
7. Verify completeness indicator updates ("5 of 7 fields collected")
8. Verify "Prefer a form?" fallback link is visible
9. Mobile (375x812): verify chat is usable, messages don't overflow, keyboard doesn't obscure input
10. Verify profile panel is accessible on mobile (expandable card or bottom sheet)

## Acceptance Criteria

- Chat conversation works end-to-end via Playwright MCP
- Streaming responses render correctly
- Profile extraction panel updates in real-time
- Mobile chat UX is smooth
- Fallback link is accessible
