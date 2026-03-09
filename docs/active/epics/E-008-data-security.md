---
id: E-008
title: data-security
status: active
---

## Customer & Client Data Security

We handle phone numbers, addresses, photos of people's homes, and payment information. This is not optional — tenant isolation and data access controls must be tested from the first migration, not retrofitted.

## Ongoing concerns

- **Tenant isolation is tested.** Every test suite includes cross-tenant access attempts that must fail. A query in tenant A's schema must never return tenant B's data. This is tested at the Ash policy layer AND at the Postgres schema layer.
- **Policy coverage is complete.** No Ash action runs without an explicit policy permitting it. CI fails if a resource has actions without policies. Crew cannot see other crew's jobs. Crew cannot see financial data. Dispatchers cannot access billing config.
- **PII is identified and handled.** Customer phone, email, address, and photos are PII. These fields are marked in resource metadata. Audit trail (AshPaperTrail) logs who accessed or modified PII.
- **Auth boundaries hold.** Unauthenticated users can only access `/`, `/scan`, `/book`, and `/healthz`. Every other route requires authentication. Session tokens are scoped to a single tenant.
- **Booking form data is safe.** Public form submissions (name, phone, address, photos) are stored in the correct tenant schema. Uploaded photos are stored with tenant-scoped S3 keys. No user input is rendered unescaped.
- **Secrets never leak.** No credentials in code, Docker images, logs, or error pages. DATABASE_URL, SECRET_KEY_BASE, Stripe keys are Fly secrets only. Error pages in prod show nothing useful to an attacker.
- **Tests run in CI.** Security tests are not a separate suite that gets skipped — they're part of the main test run. A failing security test blocks deploy just like any other test.
