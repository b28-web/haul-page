---
id: S-002
title: landing-page
status: open
epics: [E-003, E-006, E-007]
---

## Landing Page

Build the public landing page at `/`. Dark, minimal, print-friendly. Driven by operator config.

## Scope

- Server-rendered HEEx (no LiveView needed)
- CameraPlainVariable custom font
- Sections: headline, services, service area, contact/CTA
- `@media print` stylesheet — light background, dark text, hide interactive elements
- Operator config wired to template (business name, phone, tagline, colors)
- Mobile-first responsive layout
- No JavaScript required
