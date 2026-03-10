# T-033-04 Structure: Dedup QA Tests

## Files Deleted (7)

1. `test/haul_web/live/chat_qa_test.exs`
2. `test/haul_web/live/provision_qa_test.exs`
3. `test/haul_web/live/onboarding_qa_test.exs`
4. `test/haul_web/live/app/billing_qa_test.exs`
5. `test/haul_web/live/app/domain_qa_test.exs`
6. `test/haul_web/live/proxy_qa_test.exs`
7. `test/haul_web/live/admin/superadmin_qa_test.exs`

## Files Modified (6)

### 1. `test/haul_web/live/admin/accounts_live_test.exs` — NO CHANGE
superadmin_qa_test.exs is 100% duplicate, no merges needed.

### 2. `test/haul_web/live/app/domain_settings_live_test.exs`
- Add `describe "PubSub status updates"` with 1 test
- Add setup helper for provisioning domain state (reuse existing `set_company_plan` pattern)

### 3. `test/haul_web/live/app/billing_live_test.exs`
- Add `describe "feature gate cross-verification"` with 2 tests (domain page checks)
- Add `describe "dunning alerts"` with 1 test
- Add 1 test to downgrade describe block (downgrade→domain page cross-verify)
- Total new: 4 tests

### 4. `test/haul_web/plugs/proxy_routes_test.exs`
- Add tests to existing describe blocks:
  - "renders tagline and service area" → add to "GET /proxy/:slug/"
  - "form validate event works" → add to "LiveView proxy routes"
  - "chat mounts or redirects under proxy" → add to "LiveView proxy routes"
- Add `describe "cross-tenant isolation"` with 3 tests (phone, name, scan)
- Adapt setup: reuse or extend existing company creation to include SiteConfig/Service data
- Total new: 6 tests

### 5. `test/haul_web/live/chat_live_test.exs`
- Add `describe "multi-turn conversation"` with 1 test
- Add `describe "CSS layout"` with 2 tests (alignment, typing indicator)
- Add `describe "mobile profile toggle"` with 2 tests
- Add `describe "provisioning flow"` with 3 tests (trigger, complete, failed)
- Add `describe "conversation persistence"` with 1 test
- Total new: 9 tests

### 6. `test/haul_web/live/preview_edit_test.exs`
- Add `describe "pre-provision state"` with 2 tests (chat UI, building message)
- Add `describe "edit instructions"` with 1 test
- Add test to "service management" describe: "service addition creates in tenant DB"
- Add `describe "tenant page verification"` with 3 tests (landing, scan, booking)
- Add `describe "edit persistence"` with 1 test (edited content on landing)
- Add `describe "mobile preview toggle"` with 1 test
- Import `@profile` module attribute and `provision_and_enter_edit_mode` helper from QA file
- Total new: 9 tests

### 7. `test/haul_web/live/app/onboarding_live_test.exs`
- Add `describe "onboarded content quality"` with 3 tests (services, gallery+endorsements, content counts)
- Add `describe "public pages after onboarding"` with 3 tests (landing services, scan gallery, booking form)
- Add `Haul.Onboarding.run/1` based setup (conditionally, for these describe blocks only)
- Total new: 6 tests

## Ordering

1. Delete superadmin_qa_test.exs first (pure deletion, no merge)
2. domain_qa → domain_settings (1 test, smallest merge)
3. billing_qa → billing_live (4 tests)
4. proxy_qa → proxy_routes (6 tests)
5. onboarding_qa → onboarding_live (6 tests)
6. chat_qa → chat_live (9 tests)
7. provision_qa → preview_edit (9 tests, largest merge)
8. Run full test suite to verify
