---
id: S-013
title: content-admin
status: open
epics: [E-010, E-005, E-006]
---

## Content Admin UI (Phase 2)

Give operators a self-service way to edit their site content — business info, services, gallery photos, endorsements — without touching the database or asking for help.

## Scope

- Authenticated `/app` route scope with operator-only access
- SiteConfig editor: business name, phone, email, tagline, service area, colors
- Services CRUD: add/edit/remove services with title, description, icon
- Gallery manager: upload before/after photos, reorder, add captions, delete
- Endorsements manager: add/edit customer testimonials with name, text, source
- All forms backed by existing Ash Content domain resources
- Changes reflect immediately on public pages (no cache to bust — reads are live)
- Mobile-friendly admin UI (operators are often on their phone)
