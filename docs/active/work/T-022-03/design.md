# T-022-03 Design: Proxy Browser QA

## Approach

Create a single test file `test/haul_web/live/proxy_qa_test.exs` using Phoenix.LiveViewTest (not Playwright MCP). This aligns with the existing QA test pattern used in provision_qa_test.exs and chat_qa_test.exs.

### Why LiveViewTest over Playwright

1. **Consistency** — all other QA tests use LiveViewTest
2. **Speed** — no browser startup overhead
3. **Reliability** — no flaky DOM waits or network timing
4. **Sufficient coverage** — LiveViewTest exercises the full stack: plugs, hooks, LiveView mount, WebSocket events, form interactions

Playwright would only add value for CSS rendering verification, which is out of scope for this ticket (it's about routing and tenant resolution, not visual design).

### Test Structure

**Setup:** Create two companies with different slugs and provision both tenants with distinct SiteConfig/Services content. This enables cross-tenant verification.

**Test groups:**

1. **Landing page** — GET `/proxy/:slug/` renders with tenant-specific business name and services
2. **Scan page** — LiveView mount, gallery renders, links stay in proxy namespace
3. **Booking form** — LiveView mount, form renders, fields fillable under proxy
4. **Chat interface** — mount under proxy, verify it loads (or redirects gracefully)
5. **Cross-tenant** — same routes, different slug → different content
6. **LiveView events** — form submission works under proxy (WebSocket functional)

### Rejected alternatives

- **Playwright browser tests** — overkill for routing/resolution QA; adds CI complexity
- **Extending ProxyRoutesTest** — that file tests routes exist; this file tests end-to-end flows
- **One test per route** — too granular; grouping by concern is clearer

### Key decisions

- Use `Haul.AI.Provisioner.from_profile/2` to create real tenant content (same as provision_qa_test)
- Create two tenants in shared setup to enable cross-tenant assertions
- Test chat by checking mount behavior, not full chat flow (that's covered by chat_qa_test)
- async: false since we need tenant schema provisioning
