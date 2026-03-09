---
id: T-015-02
story: S-015
title: onboarding-wizard
type: task
status: open
priority: high
phase: ready
depends_on: [T-015-01, T-013-02]
---

## Context

After signup, guide the operator through personalizing their site before going live. This is where "template" becomes "my business."

## Acceptance Criteria

- `/app/onboarding` LiveView (authenticated, owner only)
- Multi-step wizard:
  1. **Confirm info** — pre-filled business name, phone, email. Edit if needed.
  2. **Choose subdomain** — auto-suggested from business name, editable. Live availability check.
  3. **Customize services** — pre-populated with defaults, add/remove/edit.
  4. **Upload logo** (optional) — drag-and-drop or file select.
  5. **Preview** — iframe or link showing their live public site.
  6. **Go Live** — button that marks site as active. Confetti optional.
- Progress indicator (step X of 6)
- Can skip steps and come back
- Completing wizard sets `Company.onboarding_complete = true`
- After completion, redirects to `/app` dashboard
