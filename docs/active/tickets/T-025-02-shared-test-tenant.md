---
id: T-025-02
story: S-025
title: shared-test-tenant
type: task
status: open
priority: medium
phase: done
depends_on: [T-025-01]
---

## Context

After T-025-01, each test file still provisions its own tenant in `setup_all`. If multiple files could share a single pre-provisioned tenant, the total provisioning cost drops further. This is the "Tier 4: structural" fix from T-024-02.

## Acceptance Criteria

- Create a shared test fixture module (e.g., `Haul.TestFixtures`) that provisions a tenant once per test suite run
- Files that only need a tenant for read-only or isolated-write tests can opt into the shared tenant
- Files that need tenant isolation (security tests, multi-tenant tests) continue provisioning their own
- Document which files use shared vs private tenants
- All tests pass across 3 runs with different seeds

## Implementation Notes

- ExUnit's `setup_all` is per-module. For cross-module sharing, consider a named ETS table or Application env populated once in `test_helper.exs`
- The shared tenant must survive sandbox checkout — it's created outside any transaction
- Be conservative: start with admin LiveView tests (10 files) that all follow the same pattern
