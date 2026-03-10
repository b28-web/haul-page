---
id: S-027
title: test-factories
status: open
epics: [E-015]
---

## Test Factories & Fixtures

Eliminate the 15-line tenant provisioning boilerplate duplicated across 50+ test files. Create a centralized factory module that handles company creation, tenant provisioning, user registration, and common resource creation.

## Scope

- Create `test/support/factories.ex` with builder functions for every Ash resource:
  - `create_tenant(name)` — company + schema provisioning + cleanup registration
  - `create_user(tenant, attrs)` — user with role, returns user + token
  - `create_service(tenant, attrs)`, `create_gallery_item(tenant, attrs)`, etc.
  - `create_authenticated_context(attrs)` — moves from ConnCase to Factories, delegates to above
- Factory functions use `System.unique_integer` for name uniqueness by default
- Each factory returns the created resource (not a changeset)
- `cleanup_tenant/1` registered automatically via `on_exit` when using `setup_all` pattern
- Update ConnCase and DataCase to import Factories
- Migrate 5-10 existing test files to use factories as proof of concept (not all 76)
- Document the factory pattern in CLAUDE.md test conventions

## Tickets

- T-027-01: core-factories — create `Haul.Test.Factories` with tenant/user/auth builders, delegate from ConnCase/DataCase
- T-027-02: resource-factories — add service/gallery/endorsement/job/page factories, migrate 5-10 files as proof
- T-027-03: migrate-data-case-tests — systematically migrate all DataCase files to use factories

## Why first

Every subsequent story in E-015 depends on having a clean factory layer. Without it, extracting unit tests still requires the same boilerplate to set up test data, and new test files will keep copy-pasting the old pattern.
