# T-017-01 Plan: Domain Settings UI

## Step 1: Migration — add domain_status to companies

Create migration adding `domain_status` string column (nullable) to `companies`.
Verify: `mix ecto.migrate` succeeds.

## Step 2: Update Company resource

Add `domain_status` atom attribute with `one_of: [nil, :pending, :verified, :provisioning, :active]`.
Add to `update_company` accept list.
Verify: existing tests still pass.

## Step 3: Create Haul.Domains module

Pure functions:
- `normalize_domain/1` — strip http(s)://, trailing slash/path, downcase
- `valid_domain?/1` — regex check for valid hostname with at least one dot
- `verify_dns/2` — `:inet_res.lookup(domain, :in, :cname)`, check if result includes base_domain

Unit tests in `test/haul/domains_test.exs`.
Verify: `mix test test/haul/domains_test.exs` passes.

## Step 4: Create DomainSettingsLive

LiveView at `lib/haul_web/live/app/domain_settings_live.ex`.

Mount:
- Read `current_company` from assigns
- Set `can_custom_domain` via `Billing.can?/2`
- Set `domain`, `domain_status` from company
- Init `domain_input` for form, `verifying` flag, `confirm_remove` flag

Render states:
1. Not on Pro+ → upgrade prompt with link to billing
2. No domain → subdomain display + add domain form
3. Domain pending → CNAME instructions + verify button
4. Domain verified/active → green status badge + remove button

Events:
- `save_domain` — validate, normalize, save to Company with status `:pending`
- `verify_dns` — call `Haul.Domains.verify_dns/2`, update status on success
- `remove_domain` — show confirm modal
- `confirm_remove` — clear domain + status
- `cancel_remove` — dismiss modal
- `validate_domain` — live validation on input change

## Step 5: Router + sidebar updates

Add route: `live "/settings/domain", App.DomainSettingsLive`
Update admin layout: make Settings expandable with Billing and Domain sub-links.

## Step 6: Integration tests

`test/haul_web/live/app/domain_settings_live_test.exs`:
- Renders page for authenticated user
- Shows upgrade prompt for starter plan
- Shows add domain form for pro+ user
- Validates domain format
- Saves domain and shows CNAME instructions
- Shows remove confirmation modal
- Removes domain on confirm
- Redirects unauthenticated users

## Step 7: Verify all tests pass

Run full test suite: `mix test`
Ensure no regressions.

## Testing Strategy

- **Unit tests**: Haul.Domains functions (normalize, validate, DNS mock)
- **Integration tests**: LiveView rendering, events, state transitions
- **Feature gate tests**: Starter vs Pro plan rendering
- **Auth tests**: Unauthenticated redirect
