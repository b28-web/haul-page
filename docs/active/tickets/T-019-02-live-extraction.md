---
id: T-019-02
story: S-019
title: live-extraction
type: task
status: open
priority: high
phase: done
depends_on: [T-019-01, T-018-03]
---

## Context

Run BAML extraction after each user message and show the operator profile building up in real-time alongside the chat. This is the "magic moment" — the operator sees their business info being understood and structured as they talk.

## Acceptance Criteria

- After each user message, run `Extractor.extract_profile/1` on the full conversation so far
- Profile panel (sidebar on desktop, expandable card on mobile) shows:
  - Business name, phone, email, service area — filled or "not yet provided"
  - Services list with inferred categories
  - Differentiators / unique selling points
  - Completeness indicator: "4 of 7 fields collected" with progress bar
- Profile updates animate (field fills in, color change from gray to white)
- Extraction runs async (doesn't block chat — user can keep typing)
- When all required fields are present: "Your profile is complete!" prompt with "Create my site" CTA
- Extraction errors are silent to user (logged server-side) — chat continues normally
- Debounce: if user sends 3 messages in rapid succession, only extract on the last one
