# T-024-03 Research: Fix Slow Tests

## Scope

Target: reduce test suite from ~173s to under 60s. T-024-02 analysis identifies three tiers of fixes:
1. **Setup deduplication** (35-40s savings) — move per-test tenant provisioning to `setup_all`
2. **Sleep reduction** (15-20s savings) — make extraction debounce configurable, reduce in test
3. **Async conversion + bcrypt** (<5s savings) — minor structural improvements

## Key Infrastructure

### Test Support Files
- `test/support/conn_case.ex` — `create_authenticated_context/1` (~150-200ms per call), `cleanup_tenants/0`, `log_in_user/2`
- `test/support/data_case.ex` — `setup_sandbox/1` with Ecto sandbox `:manual` mode
- `test/test_helper.exs` — ExUnit config, sandbox mode

### `create_authenticated_context/1` Cost Breakdown
| Step | Cost |
|------|------|
| Company.create_company | ~40ms |
| ProvisionTenant.tenant_schema (CREATE SCHEMA + migrations) | ~50-80ms |
| User.register_with_password (bcrypt, 12 rounds default) | ~30ms |
| User.update_user (role) | ~15ms |
| User.sign_in_with_password (bcrypt verify) | ~15ms |
| **Total** | **~150-200ms** |

### Extraction Debounce
- `lib/haul_web/live/chat_live.ex:19` — `@extraction_debounce_ms 800` (hardcoded module attribute)
- Used at line 836: `Process.send_after(self(), :run_extraction, @extraction_debounce_ms)`
- Chat tests sleep 1500ms after each message to wait for debounce + extraction task
- Making this configurable via `Application.get_env` would allow 50ms in test

## Files to Modify — Tier 1 (Setup Deduplication)

### Safe for `setup_all` (read-only tests)
| File | Tests | Current Setup Cost | Savings |
|------|-------|-------------------|---------|
| security_test.exs | 11 | 2 tenants + 6 users per test (~300ms × 11) | ~3.0s |
| tenant_isolation_test.exs | 10 | 2 tenants + 18 records per test (~500ms × 10) | ~4.5s |
| dashboard_live_test.exs | 7 | auth context per test (~180ms × 7) | ~1.1s |

These tests only read/assert on setup data — never mutate it. `setup_all` is straightforward.

### Requires careful handling (tests create records)
Most admin LiveView tests (services, gallery, endorsements, site_config, billing, domain, onboarding) create records within tests. However, each test gets a fresh tenant via `setup` → `create_authenticated_context()`. Moving to `setup_all` means all tests share one tenant.

**Pattern for safe sharing:** Tests that create unique records (services with unique names, gallery items) can share a tenant if they don't assert on record counts or expect empty state. Tests that assert "no items" on initial render CANNOT share a tenant.

After detailed review of each file:
- **services_live_test.exs** — test at line ~30 asserts "No services configured" → cannot share
- **gallery_live_test.exs** — test at line ~39 asserts "No gallery items yet" → cannot share
- **endorsements_live_test.exs** — test at line ~29 asserts empty page → cannot share
- **site_config_live_test.exs** — tests modify SiteConfig singleton → cannot share
- **onboarding_live_test.exs** — setup seeds content, tests are read-heavy → could share
- **billing_live_test.exs** — tests mutate company.subscription_plan → cannot share
- **billing_qa_test.exs** — tests mutate company.subscription_plan → cannot share
- **domain_settings_live_test.exs** — tests mutate company state → cannot share
- **domain_qa_test.exs** — tests mutate company.subscription_plan → cannot share
- **preview_edit_test.exs** — each test provisions separate tenant → cannot share
- **provision_qa_test.exs** — each test provisions separate tenant → cannot share

**For these files, the approach must be different:** keep per-test setup but reduce the cost of `create_authenticated_context()` itself — specifically bcrypt rounds reduction and potential schema caching.

## Files to Modify — Tier 2 (Sleep Reduction)

| File | Sleep Total | Mechanism |
|------|------------|-----------|
| chat_qa_test.exs | ~20s | ~15 × `Process.sleep(1500)` for extraction debounce |
| chat_live_test.exs | ~10s | ~15 × `Process.sleep(500-1500)` for extraction debounce |
| preview_edit_test.exs | ~0.3s | 3 × `Process.sleep(50-100)` |
| provision_qa_test.exs | ~1s | 8 × `Process.sleep(50-500)` |

The chat file sleeps are the biggest target. With debounce at 50ms in test, sleep can drop from 1500ms to ~200ms.

## Files to Modify — Tier 3 (Async + bcrypt)

### Async conversion candidates (minimal impact)
- `test/haul_web/controllers/qr_controller_test.exs` — 65ms, 10 tests, pure controller
- `test/haul_web/controllers/health_controller_test.exs` — 1ms, 1 test, stateless
- `test/haul/rate_limiter_test.exs` — 0ms, 4 tests, ETS only
- `test/haul/ai/chat_test.exs` — 263ms, 6 tests, no DB

### Bcrypt rounds
AshAuthentication uses bcrypt at default 12 rounds. No test-env override exists. Adding `config :bcrypt_elixir, log_rounds: 1` to `config/test.exs` would reduce each password hash from ~30ms to <1ms. With ~200 user registrations across the suite, that's ~6s savings.

## Constraints

1. All 55 sync files must remain `async: false` due to tenant schema DDL (global PostgreSQL state)
2. `on_exit` cleanup (DROP SCHEMA) must still run — orphaned schemas break subsequent runs
3. Chat tests require ChatSandbox mock — must remain sync
4. Tests asserting empty initial state cannot share tenant context
5. ExUnit `setup_all` callbacks run in the test process — `on_exit` in `setup_all` runs after all tests in the module

## Existing Test Count
746 tests, 0 failures (per T-024-02). Must maintain all passing.
