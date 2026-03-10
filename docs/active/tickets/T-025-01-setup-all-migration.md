---
id: T-025-01
story: S-025
title: setup-all-migration
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

The T-024-02 analysis found that 14 test files call `create_authenticated_context()` per-test, each provisioning a Postgres schema (~150-200ms). Zero files use `setup_all`. Moving these to once-per-file setup saves an estimated 35-40s of wall time.

## Acceptance Criteria

- Move `create_authenticated_context()` from `setup` to `setup_all` in these files (ordered by savings):
  1. `test/haul/tenant_isolation_test.exs` (~4.5s)
  2. `test/haul_web/live/app/onboarding_live_test.exs` (~3.9s)
  3. `test/haul_web/live/preview_edit_test.exs` (~3.0s)
  4. `test/haul_web/live/provision_qa_test.exs` (~3.3s)
  5. `test/haul/accounts/security_test.exs` (~3.0s)
  6. `test/haul_web/live/app/domain_settings_live_test.exs` (~2.7s)
  7. `test/haul_web/live/app/billing_qa_test.exs` (~2.7s)
  8. `test/haul_web/live/app/domain_qa_test.exs` (~2.3s)
  9. `test/haul_web/live/app/billing_live_test.exs` (~2.3s)
  10. `test/haul_web/live/app/services_live_test.exs` (~1.8s)
  11. `test/haul_web/live/app/gallery_live_test.exs` (~1.8s)
  12. `test/haul_web/live/app/endorsements_live_test.exs` (~1.8s)
  13. `test/haul_web/live/app/site_config_live_test.exs` (~1.3s)
  14. `test/haul_web/live/app/dashboard_live_test.exs` (~1.1s)
- Use Ecto sandbox `:auto` checkout mode with `setup_all` (not `:manual`)
- Tests that mutate shared state (create/update/delete) must either use unique names or reset state between tests
- `on_exit` tenant cleanup moves to file-level (once per module, not per test)
- All tests pass across 3 runs with different seeds
- No new flaky tests

## Implementation Notes

- `setup_all` runs outside the sandbox transaction — data persists across tests in the module
- Most admin LiveView tests are read-heavy with isolated CRUD operations using unique names — sharing a tenant is safe
- Security and isolation tests that create multiple tenants need careful handling — may need to keep per-test setup for specific describe blocks
- Check `Ecto.Adapters.SQL.Sandbox.checkout/2` with `:auto` mode for `setup_all` compatibility
