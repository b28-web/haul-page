---
id: S-011
title: first-operator-launch
status: open
epics: [E-010, E-006, E-002]
---

## First Operator Launch (Phase 1)

Get customer #1 live on a dedicated Fly deploy. Validate the product with a real hauler — does the landing page convert? Do bookings come in? Does the print flyer get used?

This is Model A: one Fly app, one Neon DB, operator config via env vars. No platform complexity. The goal is product-market fit, not scale.

## Scope

- Operator onboarding runbook: step-by-step for deploying a new operator instance
- Seed content tailored to customer #1 (real business name, services, service area)
- Verify end-to-end: landing page → print flyer → QR scan → booking form → operator notification
- Custom domain setup on Fly (CNAME + TLS cert)
- Basic monitoring: health check alerts, error tracking (Sentry/Honeybadger)
- Feedback loop: structured way to capture operator's friction points

## Exit criteria

Customer #1 has a live site at their custom domain, bookings come in, and they've used it for at least one week.
