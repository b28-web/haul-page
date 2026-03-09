---
id: S-020
title: content-generation
status: open
epics: [E-011, E-005, E-010]
---

## AI Content Generation & Auto-Provisioning (Phase 3)

Use the LLM to generate professional website content from the conversation — service descriptions, tagline, "why hire us" points — then auto-provision a complete, working site. The operator goes from chat to live site in one session.

## Scope

- BAML content generation functions:
  - Generate service descriptions from service names + conversation context
  - Generate business tagline (3 options, operator picks one)
  - Generate "why hire us" bullet points from differentiators mentioned in chat
  - Generate SEO meta description
- Content flows through BAML type validation before database insertion
- Auto-provisioning pipeline: extraction → generation → tenant creation → content seeding → site live
- Preview step: operator sees their generated site before confirming "Go Live"
- Edit-in-chat: "Actually, change the tagline to..." triggers regeneration of that field
- Cost tracking: log token usage per onboarding session, alert if costs exceed threshold
- Generated content is clearly editable — operator can change everything via content admin (S-013)
