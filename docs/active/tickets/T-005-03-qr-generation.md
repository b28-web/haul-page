---
id: T-005-03
story: S-005
title: qr-generation
type: task
status: open
priority: low
phase: ready
depends_on: [T-005-02]
---

## Context

The operator needs QR codes pointing to their `/scan` URL for print materials. Generate these server-side so they can download and use them.

## Acceptance Criteria

- QR code generation via an Elixir library (e.g., `eqrcode`)
- Accessible at `/scan/qr` or via a settings page (later)
- Outputs SVG or PNG of QR code pointing to `https://{operator-domain}/scan`
- Downloadable — operator saves and sends to their print shop
- Customizable size parameter (query param)
