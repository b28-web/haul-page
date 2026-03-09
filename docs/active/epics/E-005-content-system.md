---
id: E-005
title: content-system
status: pending
---

## Content System Health

The content layer must stay schema-driven, seed-reproducible, and editable by operators without code changes.

## Ongoing concerns

- Every content collection has an Ash resource with compile-time validated schema
- Seed files in `priv/content/` produce identical DB state across environments
- Markdown rendering via MDEx works for all content pages (write-time cached HTML)
- Image uploads land in Tigris with correct metadata
- Admin UI forms validate the same constraints as the Ash resource definitions
- AshPaperTrail tracks all content mutations
- Content changes reflect on public pages immediately (no cache staleness)
