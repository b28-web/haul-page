# T-017-01 Progress: Domain Settings UI

## Completed Steps

### Step 1: Migration ✓
- `priv/repo/migrations/20260309070000_add_domain_status_to_companies.exs` — already existed from a previous agent. Column `domain_status` (string, nullable) is in place.

### Step 2: Company resource update ✓
- Added `domain_status` atom attribute with `one_of: [:pending, :verified, :provisioning, :active]`
- Added `domain_status` to `update_company` accept list

### Step 3: Haul.Domains module ✓
- Created `lib/haul/domains.ex` with `normalize_domain/1`, `valid_domain?/1`, `verify_dns/2`
- Fixed regex issue with protocol stripping (URL path was interfering with `//` in protocol prefix)
- 15 unit tests pass in `test/haul/domains_test.exs`

### Step 4: DomainSettingsLive ✓
- Created `lib/haul_web/live/app/domain_settings_live.ex`
- Feature gating via `Billing.can?(company, :custom_domain)`
- Four UI states: upgrade prompt, add domain form, pending verification, active domain
- Events: save_domain, validate_domain, verify_dns, remove_domain, confirm_remove, cancel_remove
- Remove confirmation modal (matches billing downgrade pattern)

### Step 5: Router + sidebar ✓
- Added `live "/settings/domain", App.DomainSettingsLive` to authenticated scope
- Made Settings section expandable in sidebar (like Content), with Billing and Domain sub-links

### Step 6: Tests ✓
- 15 unit tests for Haul.Domains
- 16 integration tests for DomainSettingsLive
- All 466 tests pass, 0 failures

## Deviations from Plan
- DNS verification test not included (would require mocking `:inet_res`) — covered by manual testing
- Migration was already present from a prior agent session
