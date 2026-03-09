# T-020-05 Review: Browser QA — AI Provision Pipeline

## Summary

Created `test/haul_web/live/provision_qa_test.exs` — 14 end-to-end tests verifying the full AI onboarding pipeline: chat conversation → profile extraction → content generation → provisioning → preview/edit → go live → tenant site verification.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `test/haul_web/live/provision_qa_test.exs` | Created | 14 QA tests for full pipeline |

## Test Coverage

### Full Pipeline (4 tests)
- Chat UI renders and accepts messages
- Provisioning enters edit mode with preview panel (iframe, URL, edit counter)
- Building message shown during provisioning state
- Edit instructions displayed after provisioning

### Edit Flow (4 tests)
- Tagline regeneration updates SiteConfig in DB
- Phone number edit updates SiteConfig in DB
- Service addition creates new service in tenant
- Multiple edits increment counter correctly

### Go Live + Tenant Site (5 tests)
- Go live finalizes session with admin panel link
- Tenant landing page renders with provisioned content (phone, email, service area, services)
- Tenant /scan page renders after provisioning
- Tenant /book page renders after provisioning
- Edited content (phone number) appears on tenant landing page

### Mobile (1 test)
- Preview panel toggle works in edit mode (Show/Hide Preview)

## Acceptance Criteria Verification

| Criteria | Status |
|----------|--------|
| Full chat-to-live-site pipeline verified | ✅ 5 tests cover full path |
| Generated content on public pages | ✅ Landing page verified with business info + services |
| Edit-in-chat updates reflected in preview | ✅ Phone, tagline, service edits verified in DB |
| New tenant site fully functional | ✅ Landing (/), scan (/scan), booking (/book) all render |

## Test Results

```
14 tests, 0 failures (7.6s)
Full suite: 742 tests, 0 failures (181.5s)
```

## Open Concerns

- **No real Playwright browser tests** — Tests use Phoenix.LiveViewTest, consistent with all other QA tickets in this project. Iframe rendering and JS hook behavior (PreviewReload) are not tested at the DOM level.
- **Content generation uses BAML sandbox** — Tests verify pipeline integration, not actual LLM-generated content quality. Real content quality tested only in production.
- **Tenant cleanup relies on on_exit** — If tests crash before cleanup, tenant schemas persist until next run. Standard pattern across all tenant-creating tests.
