---
id: T-004-01
story: S-004
title: company-user-resources
type: task
status: open
priority: critical
phase: ready
depends_on: [T-002-03]
---

## Context

Define the Company and User Ash resources in the Accounts domain. Company is the tenant root. User has AshAuthentication with password + magic link.

## Acceptance Criteria

- `Haul.Accounts.Company` resource: id, slug, name, timezone, subscription_plan, stripe_customer_id
- `Haul.Accounts.User` resource: id, email, hashed_password, name, role, phone, active, company_id
- AshAuthentication configured: password strategy + magic link strategy
- Schema-per-tenant multi-tenancy via AshPostgres :context strategy
- Company creation provisions a new Postgres schema
- Migrations generated and run successfully
- Policies: owner manages all users, crew reads/updates self only
- **Security tests:**
  - Test: tenant A's user cannot read tenant B's data (cross-schema isolation)
  - Test: crew role cannot list other users, cannot access financial fields
  - Test: unauthenticated request to any `/app` route returns 401/redirect
  - Test: Company creation provisions an isolated schema; dropping tenant schema removes all tenant data
  - These tests run as part of `mix test`, not a separate suite
