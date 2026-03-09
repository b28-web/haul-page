# T-022-03 Review: Proxy Browser QA

## Summary

End-to-end QA tests for the dev proxy system. Verifies proxy routing works across all tenant-facing pages: landing, scan, booking, and chat. Tests cross-tenant isolation and LiveView WebSocket functionality under the proxy prefix.

## Full test suite

```
811 tests, 0 failures (1 excluded) — 87.6s
```

## Changes

### Created

| File | Purpose |
|------|---------|
| `test/haul_web/live/proxy_qa_test.exs` | 13 QA tests for proxy routing |

### Modified

| File | Change |
|------|--------|
| `lib/haul_web/controllers/page_controller.ex` | Use `conn.assigns[:tenant]` in `operator_home/1` instead of always reading from app config. Required for proxy landing page to show correct tenant content. |

## Test coverage (13 tests)

| Group | Tests | What's verified |
|-------|-------|----------------|
| Landing page | 2 | Business name, phone, services, tagline, service area render from correct tenant |
| Scan page | 2 | LiveView mounts, Book Online link stays in `/proxy/:slug/` namespace |
| Booking form | 2 | LiveView mounts under proxy, form validate event works |
| Chat | 1 | Mounts or redirects gracefully (handles configured/unconfigured LLM) |
| Cross-tenant | 3 | Different slugs → different business names, phones, scan content; no cross-contamination |
| LiveView WebSocket | 2 | Re-render after mount works for scan and booking |
| Error handling | 1 | Unknown slug returns 404 |

## Acceptance criteria verification

| Criterion | Status |
|-----------|--------|
| Landing page renders with correct business name and services | PASS |
| Navigate to /proxy/:slug/book, booking form renders | PASS |
| Navigate to /proxy/:slug/scan, gallery renders | PASS |
| Navigate to /proxy/:slug/start, chat loads or redirects | PASS |
| Links stay within /proxy/:slug/ namespace | PASS (verified on scan page Book Online link) |
| LiveView WebSocket connects and events work | PASS (form validate, re-render) |
| Switching slug resolves to different tenant content | PASS (3 cross-tenant tests) |

## Bug found and fixed

**PageController.operator_home/1** was using `ContentHelpers.resolve_tenant()` which reads the operator slug from application config. Under proxy, `conn.assigns.tenant` is set by `ProxyTenantResolver` but was being ignored. Fixed with a one-line change: `conn.assigns[:tenant] || ContentHelpers.resolve_tenant()`.

This bug meant proxy landing pages would always show the default operator's content, defeating the purpose of the proxy. The existing ProxyRoutesTest didn't catch this because it only asserted on HTTP status and assigns, not on rendered content.

## Open concerns

- None. All acceptance criteria met.

## Notes

- The landing page template (`home.html.heex`) doesn't have `/book` or `/scan` navigation links — it's a phone-centric CTA page. Proxy-aware link testing is done on the scan page which has the Book Online link.
- Chat test handles both configured (mounts with "Get Started") and unconfigured (redirects to `/app/signup`) states gracefully.
