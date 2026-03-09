# Test Timing Analysis — T-024-02

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total wall clock** | **172.9s** |
| Compilation (clean build) | 4.2s |
| Test helper → suite start | 22ms |
| Test execution (all files) | 172.9s |
| Sync files (sequential) | 55 files, 169.1s cumulative |
| Async files (parallel) | 30 files, 4.1s cumulative |
| Total tests | 746 (0 failures) |

**Key findings:**
1. Compilation is negligible (~4s, cached in incremental builds). The full 173s is test execution.
2. **51% of runtime (88.6s)** is in 14 files with redundant per-test tenant provisioning — each test creates a company, provisions a schema, registers a user, then tears it all down.
3. **21% of runtime (35.4s)** is in 2 chat test files dominated by `Process.sleep(1500)` calls waiting for extraction debounce.
4. All 55 sync files run sequentially. Their cumulative time ≈ wall clock time.
5. The 30 async files (4.1s cumulative) run in parallel and contribute almost nothing to wall clock.

**Projected runtime after fixes:** 60-80s (Tier 1 alone), 45-60s (all tiers).

---

## Compilation vs Execution

| Phase | Time | Notes |
|-------|------|-------|
| `mix compile --force` | 4.2s | 116 .ex files, includes CLDR generation |
| Incremental compile (no changes) | <0.5s | Typical dev workflow |
| test_helper.exs → suite_start | 22ms | ExUnit boot, formatter init |
| **Actual test execution** | **172.9s** | The entire problem |

Compilation is not a factor. Even a cold compile adds only 4s. The bottleneck is 100% test execution.

---

## Top 10 Slowest Files

| # | Module | Time | Tests | Avg/Test | Root Cause |
|---|--------|------|-------|----------|------------|
| 1 | HaulWeb.ChatQATest | 22.5s | 25 | 899ms | 1500ms extraction sleeps × 15 |
| 2 | HaulWeb.ChatLiveTest | 13.0s | 22 | 589ms | 1500ms extraction sleeps × 8 |
| 3 | HaulWeb.PreviewEditTest | 8.0s | 13 | 614ms | Tenant provisioning per test |
| 4 | Haul.Accounts.SecurityTest | 7.9s | 11 | 720ms | 2 tenants + 6 users per test |
| 5 | HaulWeb.App.DomainSettingsLiveTest | 7.9s | 16 | 495ms | Auth context per test |
| 6 | HaulWeb.App.OnboardingLiveTest | 7.7s | 14 | 552ms | Auth context + seed per test |
| 7 | HaulWeb.App.BillingQATest | 7.6s | 16 | 475ms | Auth context per test |
| 8 | HaulWeb.ProvisionQATest | 7.4s | 14 | 526ms | Full provisioning per test |
| 9 | HaulWeb.App.DomainQATest | 6.7s | 14 | 481ms | Auth context per test |
| 10 | HaulWeb.App.BillingLiveTest | 6.5s | 14 | 461ms | Auth context per test |

**These 10 files = 97.1s = 56% of total runtime.**

### Per-Test Breakdown: Slowest Individual Tests

| Time | File | Test |
|------|------|------|
| 3034ms | chat_qa_test.exs:63 | multi-turn conversation builds profile |
| 2857ms | chat_qa_test.exs:423 | rate limiting shows message limit error at 50 messages |
| 2835ms | chat_live_test.exs:99 | rate limiting enforces max message limit |
| 1580ms | chat_qa_test.exs:294 | provisioning_complete shows site URL |
| 1517ms | chat_live_test.exs:208 | differentiators render in profile panel |
| 1375ms | signup_live_test.exs:143 | rate limiting blocks excessive signups |
| 1174ms | preview_edit_test.exs:224 | edit limit enforces max 10 edit rounds |

The 3s multi-turn test and 2.8s rate-limit tests are dominated by loops with sleeps (50 messages × 50ms sleep each).

---

## Async Audit

### Files that are `async: false` (55 total, 169.1s)

**Must be sync — tenant schema DDL (21 files):**
These create/drop PostgreSQL schemas, which is global state outside Ecto sandbox.

| File | Time | Why sync |
|------|------|----------|
| Haul.Accounts.SecurityTest | 7918ms | Creates 2 tenant schemas per test |
| Haul.TenantIsolationTest | 5596ms | Creates 2 tenant schemas per test |
| Haul.Accounts.CompanyTest | 1169ms | Creates tenant schema |
| Haul.Accounts.UserTest | 2436ms | Creates tenant schema |
| Haul.AI.EditApplierTest | 3949ms | Provisions tenant |
| Haul.AI.ProvisionerTest | 1980ms | Provisions tenant |
| Haul.OnboardingTest | 1513ms | Provisions tenant |
| Haul.Content.* (6 files) | ~5400ms | Tenant schema for content CRUD |
| Haul.Operations.* (2 files) | ~1400ms | Tenant schema for job CRUD |
| Haul.Workers.* (5 files) | ~2700ms | Tenant schema for worker tests |
| Mix.Tasks.Haul.OnboardTest | 1138ms | Full onboarding provisions tenant |

**Must be sync — LiveView with tenant context (19 files):**
These use `create_authenticated_context()` which provisions a tenant schema.

| File | Time | Why sync |
|------|------|----------|
| HaulWeb.App.* (10 files) | ~64000ms | Admin panel — all provision tenant |
| HaulWeb.*Live* (6 files) | ~21000ms | Public LiveViews with tenant |
| HaulWeb.*Controller* (3 files) | ~4900ms | Controllers needing tenant |

**Must be sync — shared sandbox state (2 files):**

| File | Time | Why sync |
|------|------|----------|
| HaulWeb.ChatQATest | 22463ms | ChatSandbox global mock |
| HaulWeb.ChatLiveTest | 12959ms | ChatSandbox global mock |

**Could potentially be async (5 files, 330ms total):**

| File | Time | Tests | Notes |
|------|------|-------|-------|
| HaulWeb.QRControllerTest | 65ms | 10 | Pure controller, no DB writes |
| HaulWeb.HealthControllerTest | 1ms | 1 | Stateless health check |
| Haul.RateLimiterTest | 0ms | 4 | ETS-based, could isolate |
| Haul.AI.ChatTest | 263ms | 6 | Uses ExUnit.Case, no DB |
| Haul.Operations.Changes.EnqueueNotificationsTest | 161ms | 1 | Single test, low impact |

**Impact of converting these: negligible (<1s savings)**. They're already fast.

---

## Setup Cost Audit

### `create_authenticated_context()` — the dominant cost

Defined in `test/support/conn_case.ex`. Called per-test in ~25 files.

| Operation | Cost |
|-----------|------|
| `Company.create_company` | ~40ms |
| `ProvisionTenant.tenant_schema` (CREATE SCHEMA + migrations) | ~50-80ms |
| `User.register_with_password` (bcrypt) | ~30ms |
| `User.update_user` (role assignment) | ~15ms |
| `User.sign_in_with_password` (bcrypt verify + token) | ~15ms |
| **Total per call** | **~150-200ms** |

### Files with heaviest per-test setup

| File | Setup Description | Per-Test Cost | Tests | Total Setup |
|------|------------------|---------------|-------|-------------|
| Haul.TenantIsolationTest | 2 companies, 2 tenants, 2 users, 10 records | ~500ms | 10 | ~5000ms |
| Haul.Accounts.SecurityTest | 2 companies, 2 tenants, 6 users | ~300ms | 11 | ~3300ms |
| HaulWeb.PreviewEditTest | Auth context + provisioner + conversation | ~250ms | 13 | ~3250ms |
| HaulWeb.ProvisionQATest | Auth context + provisioner + conversation | ~250ms | 14 | ~3500ms |
| HaulWeb.App.OnboardingLiveTest | Auth context + seeder | ~300ms | 14 | ~4200ms |
| HaulWeb.App.* (8 files) | Auth context | ~180ms | ~120 total | ~21600ms |

**Total estimated setup waste: ~41,000ms (41s) — 24% of total runtime.**

### `on_exit` tenant cleanup

Most files with tenant provisioning include:
```elixir
on_exit(fn ->
  # Query information_schema for tenant_* schemas, DROP CASCADE each
end)
```
This runs after each test, adding ~20-50ms per test. With ~200 sync tests doing cleanup, that's ~4-10s total.

---

## Sleep Audit

| File | Calls | Per-Test Sleep | Purpose | Reducible? |
|------|-------|---------------|---------|-----------|
| chat_qa_test.exs | ~15 | 1500-3000ms | Extraction debounce (800ms) + render | Yes — configurable debounce |
| chat_live_test.exs | ~15 | 500-1500ms | Extraction debounce + streaming | Yes — configurable debounce |
| preview_edit_test.exs | 6 | 50-100ms | Chat message processing | Mostly no |
| provision_qa_test.exs | 8 | 50-500ms | Provisioning state transitions | Partially |
| timing_formatter_test.exs | 3 | 200ms | Testing timing measurement | No |

**Total sleep overhead: ~25-30s across all tests.**

The 1500ms sleeps in chat tests are the single biggest opportunity. The extraction debounce is hardcoded at 800ms in the LiveView — making it configurable (e.g., 50ms in test) would eliminate most of this.

---

## Bottleneck Categories

### 1. Inherently slow (keep as-is)

Tests that are slow by design and should not be optimized:
- Integration tests with multi-tenant isolation verification (security_test, tenant_isolation_test when setup is shared)
- Rate limiting tests that loop 50 times (unavoidable)
- Comprehensive CRUD test suites (admin panel)

### 2. Fixable setup — redundant provisioning (HIGHEST PRIORITY)

14 files create `authenticated_context` per-test when tests could share one:

| File | Current | Fix | Savings |
|------|---------|-----|---------|
| HaulWeb.App.DomainSettingsLiveTest | 16 × 180ms | 1 × 180ms | ~2700ms |
| HaulWeb.App.OnboardingLiveTest | 14 × 300ms | 1 × 300ms | ~3900ms |
| HaulWeb.App.BillingQATest | 16 × 180ms | 1 × 180ms | ~2700ms |
| HaulWeb.App.DomainQATest | 14 × 180ms | 1 × 180ms | ~2340ms |
| HaulWeb.App.BillingLiveTest | 14 × 180ms | 1 × 180ms | ~2340ms |
| HaulWeb.App.ServicesLiveTest | 11 × 180ms | 1 × 180ms | ~1800ms |
| HaulWeb.App.GalleryLiveTest | 11 × 180ms | 1 × 180ms | ~1800ms |
| HaulWeb.App.EndorsementsLiveTest | 11 × 180ms | 1 × 180ms | ~1800ms |
| HaulWeb.App.SiteConfigLiveTest | 8 × 180ms | 1 × 180ms | ~1260ms |
| HaulWeb.App.DashboardLiveTest | 7 × 180ms | 1 × 180ms | ~1080ms |
| Haul.Accounts.SecurityTest | 11 × 300ms | 1 × 300ms | ~3000ms |
| Haul.TenantIsolationTest | 10 × 500ms | 1 × 500ms | ~4500ms |
| HaulWeb.PreviewEditTest | 13 × 250ms | 1 × 250ms | ~3000ms |
| HaulWeb.ProvisionQATest | 14 × 250ms | 1 × 250ms | ~3250ms |

**Total estimated savings: ~35-40s**

Implementation: Move tenant provisioning to `setup_all` (runs once per file) and use Ecto sandbox `:auto` checkout with `on_exit` cleanup at file level instead of per-test.

### 3. Could be async but aren't (LOW PRIORITY)

5 files (330ms total) could be `async: true`. Impact: negligible.

### 4. Sleep/timeout overhead (MEDIUM PRIORITY)

Chat tests (35.4s total) contain ~25s of fixed sleeps. Fixes:
- Make extraction debounce configurable: `Application.get_env(:haul, :extraction_debounce_ms, 800)` → set to 50ms in test
- Replace `Process.sleep(1500)` with `assert_receive {:extraction_complete, _}, 2000` where possible
- **Estimated savings: 15-20s**

---

## Prioritized Fix List

### Tier 1: Setup deduplication (EASY — estimated savings: 35-40s)

Move `create_authenticated_context()` from per-test `setup` to `setup_all` in these files:

1. Haul.TenantIsolationTest — save ~4.5s
2. HaulWeb.App.OnboardingLiveTest — save ~3.9s
3. HaulWeb.PreviewEditTest — save ~3.0s
4. HaulWeb.ProvisionQATest — save ~3.3s
5. Haul.Accounts.SecurityTest — save ~3.0s
6. HaulWeb.App.DomainSettingsLiveTest — save ~2.7s
7. HaulWeb.App.BillingQATest — save ~2.7s
8. HaulWeb.App.DomainQATest — save ~2.3s
9. HaulWeb.App.BillingLiveTest — save ~2.3s
10. HaulWeb.App.ServicesLiveTest — save ~1.8s
11. HaulWeb.App.GalleryLiveTest — save ~1.8s
12. HaulWeb.App.EndorsementsLiveTest — save ~1.8s
13. HaulWeb.App.SiteConfigLiveTest — save ~1.3s
14. HaulWeb.App.DashboardLiveTest — save ~1.1s

**Constraint:** Tests that mutate tenant data (create/update/delete records) need careful handling — either reset state between tests or accept some coupling. Most admin LiveView tests are read-heavy with isolated CRUD operations that use unique names, so sharing a tenant is safe.

### Tier 2: Sleep reduction (MEDIUM — estimated savings: 15-20s)

1. Make extraction debounce configurable (config → 50ms in test) — save ~10s
2. Replace fixed sleeps with `assert_receive`/`Process.send_after` patterns — save ~5-10s
3. Reduce rate-limit test loop counts where possible — save ~2s

### Tier 3: Async conversion (EASY but LOW IMPACT — estimated savings: <1s)

Convert to `async: true`:
- HaulWeb.QRControllerTest
- HaulWeb.HealthControllerTest
- Haul.RateLimiterTest
- Haul.AI.ChatTest

### Tier 4: Structural (HARD — estimated savings: 10-20s)

- Shared test tenant fixture (provision once per suite via `setup_all` in a shared module)
- CI test partitioning (split sync files across workers)
- bcrypt rounds reduction in test (if not already done)

---

## Projected Runtime After Fixes

| State | Estimated Runtime | Reduction |
|-------|------------------|-----------|
| Current | 173s | — |
| After Tier 1 (setup dedup) | **95-110s** | 37-45% |
| After Tier 1+2 (+ sleep reduction) | **75-90s** | 48-57% |
| After Tier 1+2+3 (+ async) | **74-89s** | 49-57% |
| After all tiers | **55-70s** | 60-68% |

**Tier 1 alone gets us under 2 minutes.** This should be the immediate focus for T-024-03.

---

## Raw Data

- JSON timing report: `test/reports/timing.json`
- Timing formatter: `test/support/timing_formatter.ex`
- Enable: `HAUL_TEST_TIMING=1 mix test`
