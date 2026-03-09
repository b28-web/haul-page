---
id: T-011-02
story: S-011
title: customer-seed-content
type: task
status: open
priority: high
phase: done
depends_on: [T-006-03]
---

## Context

Create seed content for customer #1 using real business information. The seed files in `priv/content/` should produce a site that looks like *their* business, not a demo.

## Acceptance Criteria

- `priv/content/operators/customer-1/` directory with:
  - `site_config.yml` — real business name, phone, email, service area, tagline
  - `services/*.yml` — their actual service offerings with descriptions
  - `endorsements/*.yml` — real or realistic testimonials
  - `gallery/*.yml` — placeholder gallery entries (photos to be replaced with real ones)
- `mix haul.seed_content --operator customer-1` loads this data
- Landing page, scan page render with customer #1's branding
- Seed is idempotent — safe to re-run
