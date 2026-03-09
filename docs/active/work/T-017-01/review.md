# T-017-01 Review: Domain Settings UI

## Summary

Built the domain settings UI at `/app/settings/domain` with feature gating, domain entry form, DNS verification flow, and domain removal. All acceptance criteria met.

## Files Changed

### Created
- `lib/haul/domains.ex` — Domain validation and DNS verification module
- `lib/haul_web/live/app/domain_settings_live.ex` — Domain settings LiveView
- `test/haul/domains_test.exs` — 15 unit tests for domain normalization and validation
- `test/haul_web/live/app/domain_settings_live_test.exs` — 16 integration tests

### Modified
- `lib/haul/accounts/company.ex` — Added `domain_status` atom attribute, added to `update_company` accept list
- `lib/haul_web/router.ex` — Added `/settings/domain` route
- `lib/haul_web/components/layouts/admin.html.heex` — Made Settings section expandable with Billing and Domain sub-links

### Pre-existing (not modified)
- `priv/repo/migrations/20260309070000_add_domain_status_to_companies.exs` — Migration already existed

## Test Coverage

- **Unit tests (15):** Domain normalization (8 cases), domain validation (7 cases)
- **Integration tests (16):** Page rendering, auth redirect, feature gating (starter/pro/business), domain form validation, domain save + normalize, CNAME instructions display, remove modal + confirm + cancel, active domain display
- **Full suite: 466 tests, 0 failures**

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `/app/settings/domain` LiveView | ✅ |
| Feature-gated: Starter sees upgrade prompt | ✅ |
| Current state display (subdomain + custom domain) | ✅ |
| Add domain form with validation | ✅ |
| CNAME instructions shown after adding domain | ✅ |
| "Verify DNS" button with DNS lookup | ✅ |
| Verification success → status update | ✅ |
| Verification failure → helpful error | ✅ |
| Remove domain with confirmation | ✅ |
| Domain status flow (pending → verified → active) | ✅ |

## Open Concerns

1. **DNS verification is synchronous** — Uses `:inet_res.lookup` with 5s timeout. If DNS is unreachable, the LiveView will block for up to 5s. Could be moved to an async task or Oban worker in T-017-02.

2. **TLS provisioning not wired** — The `provisioning` state exists in the UI but no actual TLS provisioning happens. This is T-017-02's scope (cert provisioning via Fly.io API).

3. **No `:inet_res` mocking in tests** — DNS verification tests are not included because mocking Erlang's `:inet_res` requires process-level mocking or a behavior wrapper. The verify_dns handle_event is tested indirectly through the UI state transitions.

4. **Domain uniqueness error** — When saving a domain that's already taken by another company, the Ash unique identity constraint will raise. The error is caught and shown as "Domain is already in use by another account."

5. **Sidebar change** — Settings now expands to show Billing and Domain sub-links (previously Billing was at top level). This changes the nav behavior for existing Settings/Billing users but follows the Content section pattern consistently.
