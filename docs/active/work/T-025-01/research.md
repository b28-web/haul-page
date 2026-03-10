# T-025-01 Research: setup_all Migration

## Key Infrastructure

### `create_authenticated_context/1` — ConnCase (lines 42-82)
Creates Company → provisions tenant schema → registers User → sets role → generates JWT.
Returns `%{company, tenant, user, token}`. Each call costs ~150-200ms (schema provisioning dominates).

### Sandbox Configuration
- `test_helper.exs`: `Sandbox.mode(Haul.Repo, :manual)` — sandbox disabled globally
- `DataCase.setup_sandbox/1`: `Sandbox.start_owner!(Haul.Repo, shared: not tags[:async])` with `on_exit` to stop owner
- ConnCase `setup`: calls `setup_sandbox(tags)` + builds conn — runs per-test

### `cleanup_tenants/0` — ConnCase (lines 149-159)
Queries `information_schema.schemata` for `tenant_%` patterns, drops each with CASCADE.
Called in `on_exit` — runs after each test in current pattern.

## 14 Target Files — Classification

### Group A: Context created in top-level `setup` (simplest to migrate)
| File | Tests | Pattern | Mutations |
|------|-------|---------|-----------|
| gallery_live_test.exs | 11 | setup returns auth map | CRUD gallery items |
| onboarding_live_test.exs | 15 | setup creates ctx + seeds | Updates company state |

### Group B: Context created in nested describe `setup` (moderate)
| File | Tests | Pattern | Mutations |
|------|-------|---------|-----------|
| services_live_test.exs | 16 | 2 describes, nested setup | CRUD services |
| endorsements_live_test.exs | 16 | 2 describes, nested setup | CRUD endorsements |
| site_config_live_test.exs | 9 | 2 describes, nested setup | Updates site config |
| dashboard_live_test.exs | 6 | 4 describes (3 roles), nested setup | Read-only |

### Group C: Context created per-test inline (needs refactoring)
| File | Tests | Pattern | Mutations |
|------|-------|---------|-----------|
| domain_settings_live_test.exs | 18 | Each test calls authenticated_conn() | Updates company domain/plan |
| billing_qa_test.exs | 20 | Each test calls authenticated_conn() | Updates plan/stripe IDs |
| domain_qa_test.exs | 16 | Each test calls authenticated_conn() | Updates company domain/plan |
| billing_live_test.exs | 17 | Each test calls authenticated_conn() | Updates plan/stripe IDs |

### Group D: Multi-tenant / security (complex, may need per-test)
| File | Tests | Pattern | Mutations |
|------|-------|---------|-----------|
| tenant_isolation_test.exs | 9 | Creates 2 full tenant contexts | Cross-tenant assertions |
| security_test.exs | 9 | Creates 2 companies, 3 users | Role-based policy tests |
| preview_edit_test.exs | 17 | Helper creates context per test | AI chat + site provisioning |
| provision_qa_test.exs | 15 | Helper creates context per test | AI chat + site provisioning |

## Sandbox Compatibility with setup_all

**Critical constraint:** `setup_all` runs outside the sandbox transaction. Data created in `setup_all` persists across all tests in the module and is NOT rolled back automatically.

**Ecto Sandbox `:auto` mode:** When using `setup_all`, each test can checkout the sandbox in `:auto` mode — the sandbox auto-checks out a connection when needed. But data created in `setup_all` lives outside any sandbox, so it persists.

**Implication:** Tenant schemas created in `setup_all` must be cleaned up in `on_exit` at the module level (once), not per-test. Tests that mutate the shared tenant's data must either:
1. Use unique names per test (already common — `"service-#{System.unique_integer}"`)
2. Not depend on specific counts or ordering of data
3. Reset specific data in per-test `setup` if needed

## Existing Patterns for Shared State

- Services/Endorsements/Gallery tests already use unique names (`"My Service"`, `"Updated Service"`, etc.) but some create data that could collide
- Most LiveView tests assert on specific text presence, not counts — sharing is generally safe
- Tests that assert `has_element?(view, "...no services...")` would break if prior tests created services

## Risk Assessment

**Low risk:** Dashboard (read-only), SiteConfig (single shared config), simple CRUD tests with unique names
**Medium risk:** Services/Gallery/Endorsements (CRUD + reorder + delete — empty-state assertions could break)
**High risk:** TenantIsolation/Security (fundamentally need multiple independent tenants)
**Complex:** preview_edit/provision_qa (AI sandbox + rate limits + full provisioning flow per test)

## Total: 189 tests across 14 files, ~35-40s estimated savings
