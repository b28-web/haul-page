---
id: T-011-01
story: S-011
title: onboarding-runbook
type: task
status: open
priority: high
phase: ready
depends_on: [T-001-06]
---

## Context

Write a step-by-step runbook for deploying a new operator instance on Fly.io. This is the manual process — automate later. The runbook is the specification for what the CLI onboarding task (T-014-01) will eventually automate.

## Acceptance Criteria

- `docs/knowledge/operator-onboarding.md` with numbered steps:
  1. Create Fly app (`fly apps create`)
  2. Create Neon DB branch (or new project)
  3. Set secrets (`fly secrets set DATABASE_URL=... OPERATOR_NAME=... OPERATOR_PHONE=...`)
  4. Deploy (`fly deploy`)
  5. Run migrations (`fly ssh console -C "/app/bin/migrate"`)
  6. Seed content (`fly ssh console -C "/app/bin/haul eval 'Haul.Release.seed()'"`)
  7. Add custom domain (`fly certs add`)
  8. Verify: health check, landing page, booking form, print view
- Estimated time: under 30 minutes for someone following the doc
- Lists all required env vars with descriptions and example values
- Includes rollback steps (how to tear down a failed deploy)
