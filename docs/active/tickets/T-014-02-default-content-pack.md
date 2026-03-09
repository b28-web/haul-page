---
id: T-014-02
story: S-014
title: default-content-pack
type: task
status: open
priority: medium
phase: ready
depends_on: [T-006-03]
---

## Context

Create a default content pack that every new operator gets. Should look professional out of the box — a hauler signs up and their site immediately looks like a real business, not a template with Lorem Ipsum.

## Acceptance Criteria

- `priv/content/defaults/` directory with:
  - `site_config.yml` — placeholder config (values overridden by operator input)
  - `services/*.yml` — 6 standard hauling services (Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help) with real descriptions
  - `endorsements/*.yml` — 3 realistic sample testimonials (clearly marked as samples in admin UI)
  - `gallery/*.yml` — 4 placeholder gallery entries with stock-style descriptions
- Seed task loads defaults for new tenant
- Default content is editable — operator can customize everything from admin UI
- Content is good enough that an operator could go live with minimal changes
