# T-017-03 Design — Browser QA for Custom Domain Flow

## Approach Options

### Option A: Full Playwright MCP browser automation
- Start dev server, navigate in headless browser, take screenshots
- Pros: True end-to-end, visual verification
- Cons: Slow, requires running server, flaky DNS lookup, complex setup

### Option B: LiveViewTest-based QA (established pattern)
- Follow billing_qa_test.exs pattern — LiveViewTest assertions simulating browser interactions
- Pros: Fast, reliable, consistent with existing QA tests, no external deps
- Cons: Not true browser rendering

### Option C: Hybrid — LiveViewTest for logic, Playwright MCP for visual spot-check
- Core tests via LiveViewTest, one Playwright screenshot for visual verification
- Pros: Best of both
- Cons: More complex, Playwright may not be needed

## Decision: Option B — LiveViewTest-based QA

Rationale:
1. **Consistency**: All existing browser QA tickets (T-002-04, T-003-04, T-005-04, T-006-05, T-009-03, billing QA) use this pattern
2. **Reliability**: DNS verification will always fail in test (no real CNAME records). LiveViewTest can exercise the verify_dns error path cleanly
3. **Speed**: No server startup overhead, runs in `mix test`
4. **Coverage**: The existing 16 unit tests cover individual interactions; QA tests should cover multi-step user journeys

## Test Scenarios

### 1. Full domain lifecycle (Pro operator)
Navigate → see subdomain → add domain → see CNAME → attempt verify (expect DNS error) → remove domain → back to add form

### 2. Starter tier gating
Navigate → see upgrade prompt → no domain form → link to billing page

### 3. Pre-set domain states
- Pending: CNAME instructions visible, verify button present
- Provisioning: "Setting up SSL" message visible
- Active: green badge, verified tag, domain link

### 4. Domain validation
- Invalid domain rejected on change and submit
- URL normalization (https://WWW.EXAMPLE.COM/path → www.example.com)

### 5. Remove domain flow
Active domain → click remove → modal appears → cancel → modal gone → click remove again → confirm → domain cleared

### 6. PubSub status transition
Simulate `domain_status_changed` message → verify UI updates to active state

## What's NOT tested
- Actual DNS resolution (requires real CNAME records)
- Actual TLS cert provisioning (requires Fly.io API)
- True mobile viewport rendering (would need Playwright)
- Cross-browser compatibility

## Rejected Approaches
- **Playwright MCP**: Not worth the setup complexity for a LiveView page with no JS-heavy interactions. The form is standard Phoenix form handling.
- **Mocking DNS**: Could mock `Domains.verify_dns/2` but adds complexity. Testing the error path is sufficient for QA.
