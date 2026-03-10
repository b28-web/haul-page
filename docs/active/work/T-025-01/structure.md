# T-025-01 Structure: setup_all Migration

## Files Modified (12 test files + 1 helper)

### Helper Addition: `test/support/conn_case.ex`

Add new function `setup_all_authenticated_context/1`:
- Takes optional attrs (same as `create_authenticated_context/1`)
- Temporarily starts a sandbox owner for DDL operations
- Calls `create_authenticated_context/1`
- Stops the temporary sandbox owner
- Returns the context map

This encapsulates the sandbox management pattern so each test file doesn't repeat it.

```
def setup_all_authenticated_context(attrs \\ %{}) do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Haul.Repo, shared: true)
  ctx = create_authenticated_context(attrs)
  Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
  ctx
end
```

Also add `setup_sandbox_for_shared_context/0` for per-test sandbox setup without the ConnCase `setup` block (since some files use DataCase or custom setup):

```
def setup_shared_sandbox do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Haul.Repo, shared: true)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
end
```

### File Changes — Group A (top-level setup → setup_all)

**1. test/haul_web/live/app/gallery_live_test.exs**
- Add `setup_all` block calling `setup_all_authenticated_context/0`
- Add `on_exit(fn -> cleanup_tenants() end)` in setup_all
- Change per-test `setup` to: sandbox checkout + build conn + log_in_user from shared ctx
- Remove `create_authenticated_context()` from per-test setup

**2. test/haul_web/live/app/onboarding_live_test.exs**
- Add `setup_all` with context creation + seeding
- Per-test setup: sandbox + conn + log_in. Seeding may need to stay per-test if tests depend on fresh seed state.

### File Changes — Group B (nested describe setup → module setup_all)

**3. test/haul_web/live/app/services_live_test.exs**
- Add module-level `setup_all` with owner context
- Remove nested `setup` in "authenticated owner" describe that creates context
- Keep nested setup only for conn/sandbox

**4. test/haul_web/live/app/endorsements_live_test.exs**
- Same pattern as services

**5. test/haul_web/live/app/site_config_live_test.exs**
- Same pattern as services

**6. test/haul_web/live/app/dashboard_live_test.exs**
- setup_all creates 3 contexts: owner, dispatcher, crew (unique emails)
- Each describe block's setup uses the appropriate context for conn

### File Changes — Group C (per-test inline → setup_all)

**7. test/haul_web/live/app/domain_settings_live_test.exs**
- Add module-level setup_all with one context
- Each test's inline `authenticated_conn()` replaced with shared conn from setup
- Company attribute mutations (plan, domain) happen inside sandbox, roll back per-test

**8. test/haul_web/live/app/billing_qa_test.exs**
- Same pattern as domain_settings

**9. test/haul_web/live/app/domain_qa_test.exs**
- Same pattern as domain_settings

**10. test/haul_web/live/app/billing_live_test.exs**
- Same pattern as domain_settings

### File Changes — Group D (multi-tenant)

**11. test/haul/tenant_isolation_test.exs**
- setup_all creates 2 tenant contexts (unique emails)
- Per-test setup: sandbox checkout only
- on_exit in setup_all cleans up both tenant schemas
- Tests receive both contexts from setup_all

**12. test/haul/accounts/security_test.exs**
- setup_all creates 2 companies with users (different roles)
- Per-test setup: sandbox checkout only
- Tests receive both contexts from setup_all

### Files NOT Modified (2)

- test/haul_web/live/preview_edit_test.exs — kept per-test (complex AI flow)
- test/haul_web/live/provision_qa_test.exs — kept per-test (complex AI flow)

## Module Boundary

All changes are in test files. No production code changes. The only shared infrastructure change is the `setup_all_authenticated_context/1` helper in ConnCase.

## Ordering

1. ConnCase helper addition first (other files depend on it)
2. Group A files (simplest, validates the pattern)
3. Group B files (moderate complexity)
4. Group C files (needs refactoring of inline calls)
5. Group D files (most complex, highest risk)

## Verification Points

After each file: run that file's tests 3x with different seeds.
After all files: full `mix test` suite.
