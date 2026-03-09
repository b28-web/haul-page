# T-012-04 Review: Tenant Isolation Tests

## Summary

Created comprehensive tenant isolation tests verifying that data in one tenant schema is never visible from another tenant's context. All 10 tests pass. Full suite: 250 tests, 0 failures.

## Files Changed

### Created
- `test/haul/tenant_isolation_test.exs` — 10 tests across 5 describe blocks

### Modified
- None. No production code changes.

## Test Coverage

| Describe Block | Tests | What's Verified |
|---|---|---|
| job isolation | 3 | Query A → only A's jobs; query B → only B's; create in A → absent in B |
| content isolation | 4 | SiteConfig, Service, GalleryItem, Endorsement all scoped per tenant |
| authentication boundary | 1 | User in tenant A cannot sign_in_with_password via tenant B context |
| missing tenant context | 1 | Ash.read! without tenant raises Ash.Error.Invalid |
| defense in depth | 1 | Direct SQL to wrong schema returns empty rows |

**Total new tests:** 10
**Test suite total:** 250 (was 240)

## Acceptance Criteria Checklist

- [x] Test module: `test/haul/tenant_isolation_test.exs`
- [x] Setup: two companies with distinct data (jobs, content, users)
- [x] Query jobs as tenant A → only A's jobs
- [x] Query jobs as tenant B → only B's jobs
- [x] Create job in A → exists in A, not in B
- [x] Content resources (SiteConfig, Service, GalleryItem, Endorsement) scoped to tenant
- [x] User in tenant A cannot authenticate into tenant B
- [x] Ash policy enforcement: action without tenant context is rejected
- [x] Direct Ecto query with wrong schema prefix returns empty
- [x] Tests run as part of `mix test`
- [x] Failure blocks CI deploy (tests are in standard test suite)

## Coverage Gaps / Known Limitations

- **Page resource** not tested — could add but follows identical pattern to other Content resources. Low risk since the multitenancy config is identical.
- **Token resource** not directly tested for cross-tenant isolation — covered implicitly by auth boundary test (sign-in creates tokens in tenant schema).
- Tests are `async: false` due to schema DDL — adds ~8s to suite. Unavoidable with schema-per-tenant.

## Open Concerns

None. The existing `SecurityTest` covers User-specific policies and role enforcement. This module covers the remaining acceptance criteria without duplication.

## Relationship to Existing Tests

- `test/haul/accounts/security_test.exs` — User isolation + role policies (not duplicated here)
- `test/haul_web/plugs/tenant_resolver_test.exs` — HTTP-level tenant resolution
- `test/haul_web/live/tenant_hook_test.exs` — LiveView tenant assignment
- **This module** — data-layer isolation across all resource types + auth boundary + defense-in-depth
