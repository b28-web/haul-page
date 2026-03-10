---
id: T-027-03
story: S-027
title: migrate-data-case-tests
type: task
status: open
priority: medium
phase: done
depends_on: [T-027-02]
---

## Context

With factories established and proven on a handful of files (T-027-02), systematically migrate the remaining DataCase test files to use factories. This eliminates the remaining inline tenant provisioning boilerplate.

## Acceptance Criteria

- Migrate all `DataCase` test files that inline tenant provisioning to use `Haul.Test.Factories`:
  - `test/haul/accounts/company_test.exs`
  - `test/haul/accounts/user_test.exs`
  - `test/haul/accounts/security_test.exs`
  - `test/haul/tenant_isolation_test.exs`
  - `test/haul/content/*.exs` (service, gallery_item, endorsement, site_config, page tests)
  - `test/haul/operations/*.exs`
  - `test/haul/workers/*.exs`
  - `test/haul/onboarding_test.exs`
  - `test/haul/ai/edit_applier_test.exs`, `test/haul/ai/provisioner_test.exs`
  - `test/mix/tasks/haul/onboard_test.exs`
- Each migrated file replaces inline company/tenant/user creation with factory calls
- `on_exit` cleanup blocks replaced with factory-provided cleanup where applicable
- All 845+ tests pass across 3 runs with different seeds
- Net reduction in test support code: target 200+ fewer lines across all migrated files

## Implementation Notes

- Some files (tenant_isolation_test, security_test) create multiple tenants with specific configurations — factories should handle this via attrs, not special-case code
- Worker tests often need specific job states or notification records — add specialized factory functions only if the pattern repeats 3+ times
- Don't change test assertions or behavior — this is purely a setup refactor
