---
id: T-013-02
story: S-013
title: site-config-editor
type: task
status: open
priority: high
phase: ready
depends_on: [T-013-01, T-006-01]
---

## Context

Let the operator edit their site configuration — business name, phone, email, tagline, service area, brand colors — through a form in the admin UI.

## Acceptance Criteria

- `/app/content/site` LiveView form
- Fields: business_name, phone, email, tagline, service_area, primary_color
- Reads/writes to Content.SiteConfig Ash resource (scoped to current tenant)
- Real-time validation (LiveView form bindings)
- Save persists immediately — public pages reflect changes on next load
- Success flash: "Site settings updated"
- Mobile-friendly form layout
