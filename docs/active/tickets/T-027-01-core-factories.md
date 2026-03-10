---
id: T-027-01
story: S-027
title: core-factories
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

50+ test files duplicate 15-line blocks to create companies, provision tenant schemas, register users, and generate tokens. `create_authenticated_context/1` in ConnCase is the only shared helper, but it's monolithic and only available to ConnCase tests. DataCase tests copy-paste the same logic inline.

## Acceptance Criteria

- Create `test/support/factories.ex` defining `Haul.Test.Factories` module
- Core factory functions:
  - `build_company(attrs \\ %{})` — creates a Company with unique name/slug
  - `provision_tenant(company)` — provisions schema, returns tenant string
  - `build_user(tenant, attrs \\ %{})` — registers user with role (default: `:owner`), returns user + JWT token
  - `build_authenticated_context(attrs \\ %{})` — orchestrates all three, returns `%{company, tenant, user, token}`
  - `build_admin_session(attrs \\ %{})` — creates AdminUser with completed setup, returns `%{admin, token}`
- All factory functions use `System.unique_integer([:positive])` for name uniqueness
- ConnCase's `create_authenticated_context/1` delegates to `Haul.Test.Factories.build_authenticated_context/1`
- ConnCase's `create_admin_session/0` delegates to `Haul.Test.Factories.build_admin_session/1`
- DataCase imports `Haul.Test.Factories` so domain-level tests can use factories directly
- `setup_all_authenticated_context/1` and `cleanup_persistent_tenants/0` remain in ConnCase (they manage sandbox mode, which is a ConnCase concern)
- All 845+ tests pass — this is a refactor, not a behavior change
- No test files need to change yet (delegations preserve the existing API)

## Implementation Notes

- The factory module should `import` nothing from ConnCase/DataCase — it's a standalone module that calls Ash directly
- Keep `log_in_user/2` and `log_in_admin/2` in ConnCase — they need `Phoenix.ConnTest` which is a ConnCase concern
- `build_` prefix (not `create_`) to signal these are test helpers, not production code
- Consider adding `cleanup_all_tenants/0` as a factory-level function that ConnCase's `cleanup_tenants/0` can delegate to
