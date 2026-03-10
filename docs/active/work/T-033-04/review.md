# T-033-04 Review: Dedup QA Tests

## Summary

Deduplicated 7 `*_qa_test.exs` files (110 tests, 22.4s) by merging 35 unique tests into their non-QA counterparts and deleting 75 duplicates. All QA files removed. Suite reduced from 975 to 898 tests.

## Full Test Suite Result

```
mix test: 898 tests, 0 failures (77.3s)
```

## Test Pyramid

```
Tier 1 (Unit):          371 tests (41%)
Tier 2 (Resource):      159 tests (18%)
Tier 3 (Integration):   373 tests (41%)
```

Integration tier dropped from ~483 to 373 tests — the biggest contributor to the reduction since all QA tests were Tier 3 (ConnCase).

## Files Deleted (7)

1. `test/haul_web/live/admin/superadmin_qa_test.exs` — 18 tests, 100% duplicate
2. `test/haul_web/live/app/domain_qa_test.exs` — 14 tests, 13 duplicate, 1 merged
3. `test/haul_web/live/app/billing_qa_test.exs` — 16 tests, 12 duplicate, 4 merged
4. `test/haul_web/live/proxy_qa_test.exs` — 13 tests, 7 duplicate, 6 merged
5. `test/haul_web/live/onboarding_qa_test.exs` — 10 tests, 4 duplicate, 6 merged
6. `test/haul_web/live/chat_qa_test.exs` — 25 tests, 16 duplicate, 9 merged
7. `test/haul_web/live/provision_qa_test.exs` — 14 tests, 5 duplicate, 9 merged

## Files Modified (6)

| File | Before | After | Added |
|------|--------|-------|-------|
| domain_settings_live_test.exs | 17 | 18 | PubSub status update test |
| billing_live_test.exs | 15 | 19 | Feature gates, dunning, cross-page downgrade |
| proxy_routes_test.exs | 7 | 13 | Content rendering, cross-tenant isolation |
| onboarding_live_test.exs | 14 | 20 | CLI onboarding public pages, content quality |
| chat_live_test.exs | 21 | 30 | Multi-turn, CSS, mobile toggle, provisioning, persistence |
| preview_edit_test.exs | 13 | 22 | Pre-provision, tenant pages, edit persistence, mobile toggle |

## Coverage Assessment

- **No coverage lost.** Every unique assertion from QA files exists in the merged non-QA files.
- All merged tests run at the same tier (Integration/ConnCase) as before — no tier change.
- chat_live_test.exs reached 30 tests (at the suggested limit). All tests are logically grouped in distinct describe blocks.

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| Compare test-by-test for each QA file | ✓ Done in research.md |
| Classify as duplicate/unique flow/unique edge case | ✓ 75 duplicate, 35 unique |
| Delete 100% duplicate QA files | ✓ superadmin_qa_test.exs |
| Merge unique tests into non-QA counterparts | ✓ 35 tests merged into 6 files |
| QA test count reduced by ≥50% | ✓ 70% reduction (110→0 QA, 35 merged) |
| No coverage loss | ✓ All unique assertions preserved |
| All tests pass | ✓ 898 tests, 0 failures |
| `mix haul.test_pyramid` improved | ✓ Integration dropped from ~483 to 373 |

## Open Concerns

- **proxy_routes_test.exs changed to async: false** — needed for tenant cleanup. Was previously async-capable. Could be restored if tenant pool (T-035-03) provides pre-provisioned tenants.
- **Process.sleep patterns** preserved from QA tests. These are inherent to the async chat/streaming architecture and cannot be eliminated without changing the LiveView implementation.

## No Known Issues

All tests pass. No regressions detected. No new test files created.
