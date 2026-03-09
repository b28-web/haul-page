---
id: T-020-03
story: S-020
title: preview-and-edit
type: task
status: open
priority: medium
phase: implement
depends_on: [T-020-02]
---

## Context

Before going live, show the operator a preview of their generated site. Let them request changes via chat ("change the tagline", "remove that service") that trigger targeted regeneration.

## Acceptance Criteria

- After provisioning, chat UI shows "Here's your site — take a look:" with embedded preview (iframe or link)
- Preview shows the actual rendered landing page with generated content
- Operator can request changes in chat:
  - "Change the tagline to something about same-day service" → regenerate tagline only
  - "Remove the Assembly service" → remove from profile, re-provision content
  - "The phone number should be 555-9999" → update directly (no LLM needed)
- Changes that don't need LLM (phone, email, name) update immediately
- Changes that need LLM (descriptions, tagline) trigger targeted BAML calls
- Preview updates after each change
- "Looks good — go live!" button finalizes the site
- Max 10 edit rounds per session (prevent infinite loops)
