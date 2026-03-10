# T-025-02 Research: Shared Test Tenant

## Current State After T-025-01

T-025-01 migrated 12 test files from per-test to per-module (`setup_all`) tenant provisioning. Each module still provisions its own tenant schema(s). The current pattern:

```elixir
setup_all do
  ctx = setup_all_authenticated_context(role: :owner)
  on_exit(fn -> cleanup_persistent_tenants(ctx) end)
  %{ctx: ctx}
end
```

`setup_all_authenticated_context/1` (in `conn_case.ex:167-172`) temporarily switches to `:auto` mode, calls `create_authenticated_context/1`, then switches back to `:manual`. The context contains: `%{company, tenant, user, token}`.

## Files Using setup_all_authenticated_context

### Group A: Single context, read-heavy + sandbox-isolated writes (10 files)
These files create ONE owner context. Per-test data (services, gallery items, etc.) is created inside the sandbox and rolls back. Company mutations (plan changes, domain changes) also roll back.

| File | Tests | Pattern | Notes |
|------|-------|---------|-------|
| services_live_test.exs | 11 | `setup_all` → owner ctx | Creates services per-test, rolls back |
| gallery_live_test.exs | 11 | `setup_all` → default ctx | Creates gallery items per-test, rolls back |
| endorsements_live_test.exs | 11 | `setup_all` → owner ctx | Creates endorsements per-test, rolls back |
| site_config_live_test.exs | 8 | `setup_all` → owner ctx | Creates/updates config per-test, rolls back |
| onboarding_live_test.exs | 14 | `setup_all` → default ctx | Seeds content per-test via `Seeder.seed!` |
| billing_live_test.exs | 14 | `setup_all` → default ctx | Modifies company plan per-test, rolls back |
| billing_qa_test.exs | 16 | `setup_all` → default ctx | Modifies company plan per-test, rolls back |
| domain_settings_live_test.exs | 16 | `setup_all` → default ctx | Modifies company attrs per-test, rolls back |
| domain_qa_test.exs | 14 | `setup_all` → default ctx | Modifies company attrs per-test, rolls back |
| signup_live_test.exs | ? | Different — uses `setup_all` for "slug taken" test | Not a standard admin test |

### Group B: Dashboard — 3 role-specific contexts
| File | Tests | Pattern | Notes |
|------|-------|---------|-------|
| dashboard_live_test.exs | 7 | 3 contexts (owner, dispatcher, crew) | Tests role-specific page rendering |

### Group C: Custom setup_all — isolation/security tests
| File | Tests | Pattern | Notes |
|------|-------|---------|-------|
| tenant_isolation_test.exs | 10 | 2 tenants, custom setup with data seeding | Creates jobs, services, gallery, endorsements, configs in setup_all |
| security_test.exs | 11 | 2 companies, 3 users, custom setup | Tests RBAC policies across tenants |

## Key Constraints

### 1. Tenant schemas are DDL (non-transactional)
`ProvisionTenant.tenant_schema()` runs `CREATE SCHEMA ... CASCADE` — this is DDL and persists outside any sandbox transaction. This is why setup_all works: the schema survives sandbox checkout.

### 2. Per-test sandbox still needed
Even with a shared tenant, each test needs sandbox checkout for data isolation. Per-test CRUD (creating services, updating company plan) happens inside the sandbox and rolls back.

### 3. Company record is in public schema
The `companies` table is NOT tenant-scoped. Company records persist alongside tenant schemas. A shared tenant means a shared company record. Tests that modify company attributes (billing, domain tests) must still run inside sandbox so modifications roll back.

### 4. User + token are in tenant schema
Users live inside `tenant_xxx.users`. A shared tenant means shared user records. The JWT token (`AshAuthentication.Jwt.token_for_user/1`) is derived from the user — it can be re-used across modules.

### 5. Test execution order
ExUnit runs modules in undefined order. Cross-module sharing requires state established before any test module runs. `test_helper.exs` is the canonical place for this.

### 6. Async = false
All 12 migrated files use `async: false`. This means modules run sequentially. No concurrency concerns for a single shared tenant.

## How Cross-Module Sharing Works in ExUnit

Options for sharing state across modules:

1. **Application env** — `Application.put_env(:haul, :shared_test_tenant, ctx)` in test_helper.exs. Any module reads via `Application.get_env/2`.

2. **Named ETS table** — Create in test_helper.exs, modules look up. More complex but faster for large data.

3. **Agent/GenServer** — Overkill for a simple map.

4. **Module attribute in a shared module** — Can't work; module attributes are compile-time.

Application env is simplest and idiomatic for this use case. The ticket's implementation notes also suggest this.

## Cleanup Considerations

The shared tenant persists for the entire test run. Cleanup must happen:
- At the END of the test run (not per-module)
- OR at the START of the next test run (defensive, handles crashes)

`ExUnit.after_suite/1` callback can handle end-of-run cleanup. Combined with start-of-run cleanup in test_helper.exs, this is robust.

## Which Files Can Share vs Must Stay Private

**Can share (10 files):** services, gallery, endorsements, site_config, onboarding, billing, billing_qa, domain_settings, domain_qa — all need a single owner-role tenant context. Per-test data mutations happen in sandbox.

**Should stay private:**
- **dashboard_live_test.exs** — Needs 3 different roles (owner, dispatcher, crew). Could share the owner context and create dispatcher/crew in separate tenants, but the test's purpose is role verification. Simpler to keep private.
- **tenant_isolation_test.exs** — Fundamentally needs 2 independent tenants. Tests verify data doesn't leak. Sharing would undermine the test's purpose.
- **security_test.exs** — Needs 2 companies with specific role setups. Tests RBAC across tenants. Keep private.

**Conservative start:** The 9 admin LiveView files that use a single default/owner context (excluding dashboard). Dashboard can optionally share the owner context for its owner tests while keeping its own dispatcher/crew contexts.

## Savings Estimate

Currently: each of the 10 single-context files runs `setup_all_authenticated_context` once = 10 schema provisions.
With sharing: 1 shared provision + dashboard's 3 private provisions + isolation's 2 + security's 2 = 8 provisions total.
Net reduction: 10 provisions → 1 = 9 fewer schema provisions.
At ~150-200ms each: ~1.4-1.8s saved per test run.
