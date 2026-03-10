# T-027-03 Research: Migrate DataCase Tests to Factories

## Current State of Factories

`test/support/factories.ex` provides:
- `build_company/1` — creates Company with unique name
- `provision_tenant/1` — returns tenant schema string
- `build_user/2` — registers user + JWT in tenant
- `build_authenticated_context/1` — full company+tenant+user+token
- `build_admin_session/0` — admin user with JWT
- Resource factories: `build_service/2`, `build_gallery_item/2`, `build_endorsement/2`, `build_site_config/2`, `build_page/2`, `build_job/2`
- `cleanup_all_tenants/0` — drops all tenant schemas except shared-test-co

`test/support/conn_case.ex` delegates: `create_authenticated_context`, `shared_test_tenant`, `setup_all_authenticated_context`, `cleanup_persistent_tenants`, `cleanup_tenants`.

`Haul.DataCase` already `import Haul.Test.Factories` — all DataCase tests have factories available.

## Files to Migrate (from AC)

### Category A: Already using factories, already clean (from T-027-01/02)
These 6 content/operations tests already use `build_company`+`provision_tenant`+`cleanup_all_tenants()`:
- `test/haul/content/service_test.exs`
- `test/haul/content/gallery_item_test.exs`
- `test/haul/content/endorsement_test.exs`
- `test/haul/content/site_config_test.exs`
- `test/haul/content/page_test.exs`
- `test/haul/operations/job_test.exs`

**These are done. No further migration needed.**

### Category B: Inline Company+ProvisionTenant + manual SQL cleanup
Replace with `build_company`+`provision_tenant` + `on_exit(fn -> cleanup_all_tenants() end)`:
1. `test/haul/content/seeder_test.exs` — inline Company create + ProvisionTenant + manual SQL
2. `test/haul/operations/changes/enqueue_notifications_test.exs` — same pattern
3. `test/haul/workers/send_booking_email_test.exs` — same + creates Job inline
4. `test/haul/workers/send_booking_sms_test.exs` — same + creates Job inline
5. `test/haul/workers/check_dunning_grace_test.exs` — inline Company create + update + manual SQL
6. `test/haul/workers/provision_cert_test.exs` — inline Company create + update + manual SQL

### Category C: setup_all with multiple tenants + local helpers
These use `setup_all` with inline provisioning of 2+ tenants and custom helpers:
7. `test/haul/accounts/security_test.exs` — 2 tenants, 3 users, local register_user/set_role
8. `test/haul/tenant_isolation_test.exs` — 2 tenants, extensive local helpers for all resource types

### Category D: Only need cleanup replacement
Replace manual SQL on_exit with `cleanup_all_tenants()`:
9. `test/haul/onboarding_test.exs` — calls Onboarding.run, just needs cleanup
10. `test/haul/ai/edit_applier_test.exs` — calls Onboarding.run, just needs cleanup
11. `test/haul/ai/provisioner_test.exs` — just needs cleanup
12. `test/haul/workers/provision_site_test.exs` — just needs cleanup
13. `test/mix/tasks/haul/onboard_test.exs` — just needs cleanup

### Category E: Inline provisioning with local helpers
14. `test/haul/accounts/company_test.exs` — inline Company create + manual SQL (tests Company creation itself, so can't fully use factory)
15. `test/haul/accounts/user_test.exs` — inline Company+ProvisionTenant + local register_user

## Boilerplate Patterns Found

### Pattern 1: Manual SQL cleanup (appears in 10 files)
```elixir
on_exit(fn ->
  {:ok, result} = Ecto.Adapters.SQL.query(Haul.Repo, """
    SELECT schema_name FROM information_schema.schemata
    WHERE schema_name LIKE 'tenant_%' AND schema_name != 'tenant_shared-test-co'
    AND schema_name != 'tenant_shared-test-co'
  """)
  for [schema] <- result.rows do
    Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE")
  end
end)
```
Replace with: `on_exit(fn -> cleanup_all_tenants() end)`

### Pattern 2: Inline company + tenant (appears in 6 files)
```elixir
{:ok, company} = Company |> Ash.Changeset.for_create(:create_company, %{name: "..."}) |> Ash.create()
tenant = ProvisionTenant.tenant_schema(company.slug)
```
Replace with: `company = build_company(%{name: "..."})` + `tenant = provision_tenant(company)`

### Pattern 3: Local register_user helper (appears in 3 files)
Duplicated in user_test, security_test, tenant_isolation_test. Factory's `build_user/2` provides same functionality.

### Pattern 4: Local resource creation helpers in tenant_isolation_test
`create_job`, `create_site_config`, `create_service`, `create_gallery_item`, `create_endorsement` — all duplicated from factories.

## Constraints

- `company_test.exs` tests Company creation itself — can only replace cleanup, not setup
- `security_test.exs` and `tenant_isolation_test.exs` use `setup_all` with 2 tenants and need `cleanup_persistent_tenants` (not `cleanup_all_tenants`)
- Worker tests (dunning, cert) create Company then update with specific attrs — need `build_company` + update
- Some tests use `ProvisionTenant` alias directly for assertions — keep that import where needed
- `cleanup_conversations_test.exs` is NOT in scope (async: true, no tenant provisioning)

## Line Count Estimates

Current boilerplate across all 15 files: ~200 lines of inline provisioning + ~130 lines of manual SQL cleanup = ~330 lines.
After migration: ~40 lines (factory calls + cleanup_all_tenants). Net reduction: ~290 lines.
