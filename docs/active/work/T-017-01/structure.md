# T-017-01 Structure: Domain Settings UI

## Files Modified

### `lib/haul/accounts/company.ex`
- Add `domain_status` atom attribute: `nil | :pending | :verified | :provisioning | :active`
- Add `domain_status` to `update_company` accept list

### `lib/haul_web/router.ex`
- Add `live "/settings/domain", App.DomainSettingsLive` in authenticated scope

### `lib/haul_web/components/layouts/admin.html.heex`
- Add expandable Settings subsection (like Content)
- Add "Domain" sidebar link at `/app/settings/domain`
- Move "Billing" link into Settings subsection

## Files Created

### `priv/repo/migrations/TIMESTAMP_add_domain_status_to_companies.exs`
- Add `domain_status` column (string, nullable) to `companies` table

### `lib/haul/domains.ex`
- Module: `Haul.Domains`
- `verify_dns(domain, base_domain)` — CNAME lookup via `:inet_res`, returns `:ok | {:error, reason}`
- `normalize_domain(input)` — strip protocol, path, downcase
- `valid_domain?(domain)` — regex validation

### `lib/haul_web/live/app/domain_settings_live.ex`
- Module: `HaulWeb.App.DomainSettingsLive`
- Mount: load company, check feature gate, set assigns
- Assigns: `domain_form`, `domain_status`, `verifying`, `can_custom_domain`
- Events: `save_domain`, `verify_dns`, `remove_domain`, `confirm_remove`, `cancel_remove`
- Render: conditional UI based on plan + domain state

### `test/haul/domains_test.exs`
- Unit tests for `normalize_domain`, `valid_domain?`, `verify_dns`

### `test/haul_web/live/app/domain_settings_live_test.exs`
- LiveView integration tests: feature gating, form submission, DNS verification, domain removal

## Module Boundaries

```
HaulWeb.App.DomainSettingsLive
  ├── reads: socket.assigns.current_company
  ├── calls: Haul.Billing.can?/2 (feature gate)
  ├── calls: Haul.Domains.verify_dns/2 (DNS check)
  ├── calls: Haul.Domains.normalize_domain/1 (input cleanup)
  ├── calls: Haul.Domains.valid_domain?/1 (validation)
  └── calls: Ash.Changeset + Ash.update (Company updates)

Haul.Domains (new pure module)
  ├── normalize_domain/1 — string cleanup
  ├── valid_domain?/1 — format validation
  └── verify_dns/2 — :inet_res CNAME lookup
```

## Ordering
1. Migration (domain_status column)
2. Company resource update (accept domain_status)
3. Haul.Domains module
4. DomainSettingsLive LiveView
5. Router + sidebar nav updates
6. Tests
