---
id: S-014
title: cli-onboarding
status: open
epics: [E-010, E-001]
---

## CLI Onboarding (Phase 2)

A Mix task that provisions a new operator on the shared multi-tenant instance in under 2 minutes. This is the bridge between "developer sets up each operator" and "operator signs up themselves."

## Scope

- `mix haul.onboard` interactive task: prompts for business name, phone, email, service area
- Creates Company (tenant root) with slug derived from business name
- Provisions tenant schema (migrations run in new schema)
- Seeds default content: generic services, placeholder gallery, sample endorsements
- Outputs the operator's live URL (`slug.haulpage.com`)
- Creates initial owner User with temporary password or magic link
- Idempotent: running again for same slug updates rather than duplicates
- Also works non-interactively with flags: `mix haul.onboard --name "Joe's Hauling" --phone 555-1234 --email joe@example.com`
