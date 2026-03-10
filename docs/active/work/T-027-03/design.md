# T-027-03 Design: Migrate DataCase Tests to Factories

## Decision: Mechanical replacement using existing factories

The factories from T-027-01/02 already cover all needed patterns. No new factory functions required. This is a mechanical find-and-replace migration.

### Approach

For each file, apply the minimal set of changes:

1. **Replace manual SQL cleanup** with `on_exit(fn -> cleanup_all_tenants() end)` (Category B, D, E files)
2. **Replace inline Company+ProvisionTenant** with `build_company/1` + `provision_tenant/1` (Category B, E files)
3. **Replace inline Job creation** with `build_job/2` where applicable (booking email/SMS tests)
4. **Remove local helper functions** that duplicate factory functions (Category C files)
5. **Remove unused aliases** (`ProvisionTenant`, `Company`) after migration

### Special cases

**company_test.exs**: Cannot replace Company creation in test bodies (that's what it's testing). Only replace the on_exit cleanup.

**user_test.exs**: Replace setup's inline Company+ProvisionTenant with factories. Keep the local `register_user` helper — it tests User registration specifically and returns `{:ok, user}` (factory returns `%{user, token}`).

**security_test.exs**: Uses `setup_all` with 2 tenants. Replace inline Company creation with `build_company`, `provision_tenant`. Replace local `register_user` with factory's `build_user`. Keep `set_role` helper (factory's `build_user` already handles role, but some tests need it on existing users). Actually, looking closer: the `register_user` helper returns just the user (not a map with token), and `build_user` returns `%{user, token}`. The test references `ctx.owner_a`, `ctx.crew_a` directly as users. We can use `build_user(tenant, %{email: ...}).user` and `build_user(tenant, %{email: ..., role: :owner}).user`. But `set_role` is called separately. Since `build_user` already accepts `:role` attr, we can just pass role to `build_user` and skip `set_role`. Use `setup_all_authenticated_context` pattern with `cleanup_persistent_tenants`.

**tenant_isolation_test.exs**: Uses `setup_all` with 2 tenants + many resources. Replace all local helpers with factory calls. The local helpers (`create_tenant`, `register_owner`, `create_job`, etc.) map 1:1 to factory functions.

**check_dunning_grace_test.exs / provision_cert_test.exs**: Create Company then update with specific attrs (stripe_customer_id, domain, etc.). Use `build_company` + inline update (the update is test-specific, not a factory concern).

**onboarding_test.exs, edit_applier_test.exs, provisioner_test.exs, provision_site_test.exs, onboard_test.exs**: These only need cleanup replacement. Their setup logic is specific to what they test (Onboarding.run, Provisioner.from_profile, etc.).

### Rejected alternatives

**A: Add setup_all + shared tenant to all files** — Rejected. These tests create/modify tenant data and need isolated tenants per test or per module. Shared tenant only works for read-only tests.

**B: Create more specialized factory functions** (e.g., `build_dunning_company/1`) — Rejected. These patterns appear once. Only add factory functions for patterns repeated 3+ times per AC.

**C: Batch all files into one commit** — Rejected. Commit per category or per logical group for easier review and bisection.

### Files NOT being changed

- `test/haul/content/service_test.exs` — already migrated
- `test/haul/content/gallery_item_test.exs` — already migrated
- `test/haul/content/endorsement_test.exs` — already migrated
- `test/haul/content/site_config_test.exs` — already migrated
- `test/haul/content/page_test.exs` — already migrated
- `test/haul/operations/job_test.exs` — already migrated
- `test/haul/workers/cleanup_conversations_test.exs` — not in scope
