---
id: E-010
title: saas-platform
status: active
---

## SaaS Platform Evolution

Transform haul-page from a single-operator deploy into a multi-tenant SaaS platform with self-service onboarding, tiered pricing, and near-zero marginal cost per operator.

### Phased approach

**Phase 1 — First Customer (Model A).** Ship a dedicated deploy for customer #1. One Fly app, one Neon DB, operator config via env vars. Validate the product with a real hauler. This is already nearly complete — the current codebase supports this.

**Phase 2 — Hybrid Platform.** Add tenant routing (subdomain + custom domain), content admin UI, and CLI-driven onboarding so a second operator can go live in under 10 minutes without code changes. Customer #1 stays on their dedicated deploy. New operators share a multi-tenant instance.

**Phase 3 — Self-Service SaaS.** Public signup flow, Stripe subscription billing, automated provisioning. An operator finds the site, signs up, gets a working site in 2 minutes, pays when they want premium features. Aggressive pricing enabled by shared infrastructure and scale-to-zero.

### Pricing model target

| Tier | Price | Includes |
|---|---|---|
| Starter | $0 | Subdomain, default theme, 50 bookings/mo, email notifications |
| Pro | $29/mo | Custom domain, SMS notifications, unlimited bookings, gallery, QR materials |
| Business | $79/mo | Priority support, advanced analytics, payment collection, crew app access |
| Dedicated | $149/mo | Isolated deploy, custom branding, SLA, dedicated database |

Marginal cost per shared-tenant operator is <$1/mo (Neon branching + Fly scale-to-zero). The Starter tier is a true free tier — acquisition funnel, not a loss leader.

## Ongoing concerns

- Tenant isolation must remain airtight as the platform grows — every new feature gets cross-tenant tests
- Onboarding friction is the #1 growth lever — measure time-to-live-site and optimize ruthlessly
- Dedicated deploy option must stay viable — same image, same config, just isolated infra
- Pricing must stay simple and transparent — no per-seat, no usage surprises
- Operator data portability — if they leave, they can export their content and bookings
