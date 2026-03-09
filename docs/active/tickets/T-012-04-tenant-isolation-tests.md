---
id: T-012-04
story: S-012
title: tenant-isolation-tests
type: task
status: open
priority: critical
phase: ready
depends_on: [T-012-02]
---

## Context

Tenant isolation is the single most important security property of the platform. If operator A can see operator B's bookings, the product is dead. These tests must be comprehensive and run in CI on every push.

## Acceptance Criteria

- Test module: `test/haul/tenant_isolation_test.exs`
- Setup: create two companies (tenants) with distinct data (jobs, content, users)
- Tests:
  - Query jobs as tenant A → only tenant A's jobs returned
  - Query jobs as tenant B → only tenant B's jobs returned
  - Create job in tenant A's context → job exists in A, not in B
  - Content resources (SiteConfig, Services, etc.) scoped to tenant
  - User in tenant A cannot authenticate into tenant B
  - Ash policy enforcement: action without tenant context is rejected
  - Direct Ecto query with wrong schema prefix returns empty (defense in depth)
- Tests run as part of `mix test` (not a separate suite)
- Failure blocks CI deploy
