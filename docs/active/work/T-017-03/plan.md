# T-017-03 Plan — Browser QA for Custom Domain Flow

## Implementation Steps

### Step 1: Create test file with setup and helpers
- Create `test/haul_web/live/app/domain_qa_test.exs`
- Module: `HaulWeb.App.DomainQATest`
- Setup: `use HaulWeb.ConnCase, async: false`, cleanup on exit
- Helpers: `authenticated_conn/2`, `set_company_plan/2`

### Step 2: Implement starter tier gating tests
- Test: renders upgrade prompt for starter (default) plan
- Test: shows billing link in upgrade prompt
- Test: does not show domain form for starter

### Step 3: Implement full domain lifecycle test
- Test: Pro operator can navigate, see subdomain, add domain, see CNAME, attempt verify (DNS error), remove domain
- Chain: `live/2` → assert subdomain → `render_submit` save_domain → assert CNAME → `render_click` verify_dns → assert error → `render_click` remove_domain → confirm_remove → assert add form returns

### Step 4: Implement pre-set state tests
- Test: pending state shows CNAME instructions + verify button
- Test: provisioning state shows SSL setup message
- Test: active state shows green badge + verified tag + domain link

### Step 5: Implement domain validation tests
- Test: invalid domain shows error on submit
- Test: URL normalization works (https://WWW.EXAMPLE.COM → www.example.com)

### Step 6: Implement remove domain flow tests
- Test: cancel remove dismisses modal
- Test: confirm remove clears domain and returns to add form

### Step 7: Implement PubSub test
- Test: sending `:domain_status_changed` to LiveView updates UI

### Step 8: Run tests and fix any failures
- `mix test test/haul_web/live/app/domain_qa_test.exs`
- Fix any issues

## Testing Strategy
- All tests use LiveViewTest assertions
- No external services needed
- DNS verify will show error state (expected — no real CNAME)
- PubSub test uses `send/2` to LiveView pid

## Verification
- All tests pass
- Tests cover all 7 items from ticket test plan
- No overlap with existing unit tests (QA focuses on multi-step flows)
