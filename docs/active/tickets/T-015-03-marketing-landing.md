---
id: T-015-03
story: S-015
title: marketing-landing
type: task
status: open
priority: medium
phase: done
depends_on: [T-012-01]
---

## Context

The bare `haulpage.com` domain needs a marketing page that sells the platform to haulers. This is distinct from an operator's landing page — it sells the *product*, not the operator's *services*.

## Acceptance Criteria

- `/` on bare domain (no subdomain) serves marketing page, not operator page
- TenantResolver plug distinguishes: subdomain → operator site, bare domain → marketing site
- Page content:
  - Hero: "Your hauling business online in 2 minutes" + CTA to `/signup`
  - Demo: link to live demo operator site
  - Pricing: Starter (free), Pro ($29/mo), Business ($79/mo), Dedicated ($149/mo)
  - Features: what operators get (site, booking, notifications, print flyers, QR codes)
  - Social proof: operator testimonials (when available)
- Mobile-responsive, same design system (dark theme, Oswald/Source Sans 3)
- No auth required
