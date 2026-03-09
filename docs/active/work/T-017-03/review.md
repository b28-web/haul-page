# T-017-03 Review — Browser QA for Custom Domain Flow

## Summary

Created end-to-end browser QA tests for the custom domain settings UI, verifying the full user journey across tier gating, domain lifecycle, validation, status transitions, and removal.

## Files Created

- `test/haul_web/live/app/domain_qa_test.exs` — 14 tests in 7 describe blocks

## Files Modified

None.

## Test Coverage

### Acceptance Criteria Mapping

| Criterion | Test(s) | Status |
|---|---|---|
| Domain settings UI renders correctly for Pro+ | `pre-set domain states` (3 tests) + `domain lifecycle` | PASS |
| Shows gate for Starter | `starter tier gating` (3 tests) | PASS |
| CNAME instructions are clear and correct | `domain lifecycle` + `pre-set domain states: pending` | PASS |
| Status updates are visible | `PubSub status transition` + `pre-set domain states` | PASS |

### Test Plan Coverage

| Test Plan Item | Covered By |
|---|---|
| 1. Navigate to `/app/settings/domain` as Pro-tier | `domain lifecycle` test |
| 2. Verify current subdomain URL displayed | `starter tier gating: shows subdomain` + `domain lifecycle` |
| 3. Enter custom domain in form | `domain lifecycle` + `domain validation` (3 tests) |
| 4. CNAME instructions with correct target | `domain lifecycle` + `pre-set domain states: pending` |
| 5. Click "Verify DNS" — status update | `domain lifecycle` (DNS error path) |
| 6. Starter-tier: upgrade prompt | `starter tier gating` (3 tests) |
| 7. Mobile: form usable | Not tested (requires Playwright viewport — see open concerns) |

### Test Results

```
14 tests, 0 failures (11.2s)
```

## Open Concerns

1. **Mobile viewport not tested** — LiveViewTest doesn't support viewport simulation. Would need Playwright MCP for true responsive testing. The existing CSS uses `max-w-3xl` which is naturally responsive, so risk is low.

2. **DNS verification only tests error path** — No real CNAME records in test environment, so `verify_dns` always hits error. The success path (pending → provisioning → active) is covered via pre-set states and PubSub simulation.

3. **No cross-browser testing** — LiveViewTest renders server-side HTML only. Visual cross-browser issues would need Playwright.

## Relationship to Existing Tests

The existing `DomainSettingsLiveTest` (16 tests) covers individual interactions in isolation. This QA test adds:
- **Multi-step lifecycle flow** (add → CNAME → verify → remove in one test)
- **PubSub-driven status transition** (provisioning → active via message)
- **Billing link verification** in upgrade prompt
- **DB state verification** after removal

Total domain settings test coverage: 30 tests (16 unit + 14 QA).
