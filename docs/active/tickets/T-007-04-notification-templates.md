---
id: T-007-04
story: S-007
title: notification-templates
type: task
status: open
priority: medium
phase: ready
depends_on: [T-007-03]
---

## Context

Create well-formatted email and SMS templates for the initial notification triggers. Email gets both plain-text and HTML variants. SMS stays under 160 chars where possible.

## Acceptance Criteria

- `Haul.Notifications.BookingEmail` module builds Swoosh email with:
  - Customer confirmation: "We received your request" + summary of submitted info
  - Operator alert: customer name, phone, address, item description, link to admin
  - Both plain-text and HTML (simple, inline-styled — no CSS framework)
  - Operator branding: business name and phone from runtime config
- SMS templates:
  - Operator alert: "New booking from {name} — {phone}. {address}" (< 160 chars)
- Templates tested with ExUnit — assert subject, to/from, body contains expected fields
- Preview-able in dev via Swoosh mailbox viewer
