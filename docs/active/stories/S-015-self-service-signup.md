---
id: S-015
title: self-service-signup
status: open
epics: [E-010, E-003]
---

## Self-Service Signup (Phase 3)

Public signup flow so an operator can go from "I found this product" to "my site is live" in under 2 minutes with zero human intervention.

## Scope

- Public `/signup` page: business name, owner email, phone, service area
- On submit: create Company + tenant schema + default content + owner User
- Redirect to `/app/onboarding` wizard:
  1. Confirm business info
  2. Choose subdomain (auto-suggested from business name, editable)
  3. Upload logo (optional)
  4. Preview their live site
  5. "Go Live" button
- Starter tier is free — no payment required to launch
- Welcome email with login link and getting-started guide
- Site is live at `slug.haulpage.com` immediately after step 5
- Signup rate limiting and abuse prevention (honeypot, rate limit by IP)
