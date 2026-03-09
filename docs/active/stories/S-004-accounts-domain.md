---
id: S-004
title: accounts-domain
status: open
epics: [E-004, E-008]
---

## Accounts Domain

Set up the Accounts Ash domain with Company (tenant root) and User resources. Authentication via AshAuthentication.

## Scope

- Company resource (tenant root — slug, name, timezone, subscription_plan)
- User resource (email, password, role, phone)
- AshAuthentication: password + magic link strategies
- Schema-per-tenant multi-tenancy via AshPostgres :context
- Tenant provisioning on Company creation
- Role-based policies (owner, dispatcher, crew)
