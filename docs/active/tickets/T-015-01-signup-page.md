---
id: T-015-01
story: S-015
title: signup-page
type: task
status: open
priority: high
phase: ready
depends_on: [T-012-01, T-014-01]
---

## Context

Build the public signup page where a hauler creates their account and site. This is the top of the SaaS funnel — must be fast, simple, and confidence-inspiring.

## Acceptance Criteria

- `/signup` LiveView page (public, no auth required)
- Form fields: business name, owner email, phone, service area
- Real-time validation:
  - Email format + uniqueness
  - Phone format
  - Business name → suggested slug (shown live: "Your site: joes-hauling.haulpage.com")
  - Slug uniqueness check (debounced)
- Submit triggers tenant provisioning (same as `mix haul.onboard` under the hood)
- On success: auto-login owner, redirect to `/app/onboarding`
- Rate limiting: max 5 signups per IP per hour
- Honeypot field for basic bot prevention
- Page design: clean, dark theme, minimal — "Get your hauling site live in 2 minutes"
