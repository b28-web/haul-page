# T-027-01 Design: Core Factories

## Approach

**Extract-and-delegate.** Move the business logic from ConnCase into a new `Haul.Test.Factories` module, then have ConnCase delegate to it. This is the simplest approach with zero risk to existing tests.

### Why not other approaches?

**Option A: ExMachina-style factory library** — Rejected. ExMachina targets Ecto directly; our resources use Ash actions, not Ecto changesets. Would add a dependency for no real benefit.

**Option B: Factories in DataCase** — Rejected. DataCase is a CaseTemplate with `using` block semantics. Factories should be a standalone module importable from anywhere.

**Option C: Keep helpers in ConnCase, just add imports to DataCase** — Rejected. ConnCase helpers depend on `Phoenix.ConnTest` being available. DataCase tests don't have that. The ticket correctly identifies that factory functions should be standalone.

## Design

### Module: `Haul.Test.Factories`

```
build_company(attrs \\ %{})          -> Company struct
provision_tenant(company)            -> tenant string
build_user(tenant, attrs \\ %{})     -> %{user, token}
build_authenticated_context(attrs)   -> %{company, tenant, user, token}
build_admin_session(attrs \\ %{})    -> %{admin, token}
cleanup_all_tenants()                -> :ok
```

Key decisions:
1. **`build_` prefix** — signals test helpers, not production code
2. **`build_user/2` returns `%{user, token}`** — callers always need the token; returning both avoids a second call
3. **`build_authenticated_context/1` orchestrates all three** — identical to current `create_authenticated_context/1` logic
4. **`cleanup_all_tenants/0`** — the nuclear cleanup currently in ConnCase, moved here so DataCase tests can use it too
5. **No imports from ConnCase/DataCase** — standalone module calling Ash directly

### ConnCase changes

- `create_authenticated_context/1` delegates to `Factories.build_authenticated_context/1`
- `create_admin_session/0` delegates to `Factories.build_admin_session/0`
- `cleanup_tenants/0` delegates to `Factories.cleanup_all_tenants/0`
- `log_in_user/2`, `log_in_admin/2`, `clear_rate_limits/0`, `shared_test_tenant/0`, `setup_all_authenticated_context/1`, `cleanup_persistent_tenants/1` stay in ConnCase (conn/sandbox concerns)

### DataCase changes

- Add `import Haul.Test.Factories` to `using` block

### SharedTenant changes

- `provision!/0` calls `Haul.Test.Factories.build_authenticated_context/1` instead of `HaulWeb.ConnCase.create_authenticated_context/1`

## Risk assessment

**Low risk.** This is a pure refactor with delegation. No test files change. The API surface remains identical. The only way this breaks is if the delegation introduces a subtle difference — which it won't since we're literally moving code.
