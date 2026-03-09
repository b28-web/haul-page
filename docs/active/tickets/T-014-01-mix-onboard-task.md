---
id: T-014-01
story: S-014
title: mix-onboard-task
type: task
status: open
priority: high
phase: ready
depends_on: [T-012-01, T-006-03]
---

## Context

Build a Mix task that provisions a new operator tenant on the shared multi-tenant instance. This replaces the manual runbook for operators on the shared platform.

## Acceptance Criteria

- `mix haul.onboard` interactive mode:
  - Prompts: business name, phone, email, service area
  - Derives slug from business name (lowercase, hyphenated, uniqueness check)
  - Creates Company with slug
  - Provisions tenant schema (runs migrations in new schema)
  - Seeds default content (generic services, placeholder gallery, sample endorsements)
  - Creates owner User with magic link invite
  - Prints: "Site live at https://slug.haulpage.com"
- Non-interactive mode: `mix haul.onboard --name "Joe's Hauling" --phone 555-1234 --email joe@ex.com --area "Seattle, WA"`
- Idempotent: re-running for existing slug updates content, doesn't duplicate
- Rollback on failure: if any step fails, clean up partial state
- Works in production via release eval: `bin/haul eval "Haul.Release.onboard(...)"`
