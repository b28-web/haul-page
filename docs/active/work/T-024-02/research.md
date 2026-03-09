# T-024-02 Research: Timing Analysis

## Timing Telemetry Results

**Environment:** `HAUL_TEST_TIMING=1 mix test` via T-024-01 formatter.

### High-Level Numbers

| Metric | Value |
|--------|-------|
| Wall clock | 172.9s |
| Compilation (from scratch) | 4.2s (measured via `mix compile --force`) |
| Setup overhead (test_helper → suite_start) | 22ms |
| Test execution | 172.9s |
| Sync file cumulative time | 169.1s (55 files) |
| Async file cumulative time | 4.1s (30 files) |
| Total tests | 746 |

Compilation is negligible (~4s, cached in incremental builds). The entire 173s is test execution.

### Top 10 Slowest Files

| Rank | File | Time | Tests | Avg | Async |
|------|------|------|-------|-----|-------|
| 1 | HaulWeb.ChatQATest | 22.5s | 25 | 899ms | sync |
| 2 | HaulWeb.ChatLiveTest | 13.0s | 22 | 589ms | sync |
| 3 | HaulWeb.PreviewEditTest | 8.0s | 13 | 614ms | sync |
| 4 | Haul.Accounts.SecurityTest | 7.9s | 11 | 720ms | sync |
| 5 | HaulWeb.App.DomainSettingsLiveTest | 7.9s | 16 | 495ms | sync |
| 6 | HaulWeb.App.OnboardingLiveTest | 7.7s | 14 | 552ms | sync |
| 7 | HaulWeb.App.BillingQATest | 7.6s | 16 | 475ms | sync |
| 8 | HaulWeb.ProvisionQATest | 7.4s | 14 | 526ms | sync |
| 9 | HaulWeb.App.DomainQATest | 6.7s | 14 | 481ms | sync |
| 10 | HaulWeb.App.BillingLiveTest | 6.5s | 14 | 461ms | sync |

These 10 files account for **97.1s** — 56% of total runtime.

### Async Audit

**55 sync files** (169.1s cumulative) vs **30 async files** (4.1s cumulative).

Sync files fall into categories:

1. **Multi-tenant schema tests (must be sync):** Tests that CREATE/DROP tenant schemas cannot share the sandbox safely. ~21 files use `on_exit` schema cleanup.
2. **LiveView admin tests (sync due to tenant setup):** All `HaulWeb.App.*` tests provision a tenant per-test via `create_authenticated_context()`. This requires `async: false` because schema creation is global state.
3. **Chat/AI tests with shared sandbox state:** ChatSandbox uses process-level mocking that breaks with async.
4. **Potentially async but marked sync:** `HaulWeb.QRControllerTest` (65ms, 10 tests), `HaulWeb.HealthControllerTest` (1ms), `Haul.RateLimiterTest` (0ms) — these don't appear to need sync.

### Setup Cost Analysis

The dominant setup pattern is `create_authenticated_context()` (defined in `conn_case.ex`):
- Creates company via Ash (~40ms)
- Provisions tenant schema (~50-80ms)
- Registers user with bcrypt (~30ms)
- Signs in + generates token (~15ms)
- **Total: ~150-200ms per call**

This is called **per-test** in most LiveView/admin test files. With 10-16 tests per file, setup alone costs 1.5-3.2s per file.

Worst offenders:
- **security_test.exs**: Creates 2 companies + 2 tenants + 6 users per test (~300ms setup × 11 = 3.3s wasted)
- **tenant_isolation_test.exs**: Creates 2 companies + 2 tenants + 18 Ash records per test (~500ms × 10 = 5.0s wasted)
- **preview_edit_test.exs**: Provisions tenant + seeds content per test (~250ms × 13 = 3.3s wasted)

### Sleep Inventory

5 files contain explicit `Process.sleep` calls:

| File | Sleep calls | Total sleep per test | Purpose |
|------|------------|---------------------|---------|
| chat_qa_test.exs | ~15 calls | 1500-3000ms | Extraction debounce + streaming |
| chat_live_test.exs | ~15 calls | 500-1500ms | Extraction debounce + streaming |
| preview_edit_test.exs | 6 calls | 50-100ms | Chat interaction waits |
| provision_qa_test.exs | 8 calls | 50-500ms | Provisioning state transitions |
| timing_formatter_test.exs | 3 calls | 200ms | Testing timing itself |

Chat tests have 1500ms sleeps for extraction task debounce — these are the largest single contributor to per-test time in chat files.

### Bottleneck Categories

| Category | Files | Cumulative Time | % of Total |
|----------|-------|----------------|-----------|
| Sleep-dominated (chat) | 2 | 35.4s | 20.5% |
| Redundant per-test setup | 14 | 88.6s | 51.2% |
| Moderate setup overhead | 7 | 17.3s | 10.0% |
| Already fast | 62 | 31.9s | 18.4% |

The critical path is sync files running sequentially. Since all 55 sync files run one-at-a-time, their times add directly to wall clock.

### Existing Infrastructure

- `test/support/conn_case.ex` — `create_authenticated_context/1`, `cleanup_tenants/0`
- `test/support/data_case.ex` — Ecto sandbox setup
- `test/support/timing_formatter.ex` — T-024-01 telemetry formatter
- Ecto sandbox in `:manual` mode (test_helper.exs)
- `max_cases: 20` (ExUnit default for async parallelism)
