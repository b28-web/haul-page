# Test Architecture — 3-Tier Model

Guide for choosing the right test tier. Default to the lowest viable tier.

## Overview

| Tier | Test case | DB | HTTP | Async | Speed |
|------|-----------|:--:|:----:|:-----:|-------|
| 1 — Unit | `ExUnit.Case, async: true` | No | No | Yes | <100ms |
| 2 — Resource | `Haul.DataCase, async: false` | Yes | No | No | 100ms–1s |
| 3 — Integration | `HaulWeb.ConnCase, async: false` | Yes | Yes | No | 500ms–3s |

## Decision Tree

```
Does it need the database?
├── No  → Tier 1 (Unit)
└── Yes → Does it need HTTP or LiveView?
          ├── No  → Tier 2 (Resource)
          └── Yes → Tier 3 (Integration)
```

If you're testing a pure function that transforms data, it's Tier 1. If you're testing an Ash action (create, read, update, destroy), it's Tier 2. If you're testing a controller response, LiveView mount/event, or plug behavior, it's Tier 3.

## Tier 1: Unit Tests

Test pure functions with no side effects. No database, no GenServer, no ETS.

```elixir
defmodule Haul.FormattingTest do
  use ExUnit.Case, async: true

  test "format_price/1 formats cents to dollars" do
    assert Haul.Formatting.format_price(2999) == "$29.99"
  end
end
```

**Codebase examples:**
- `test/haul/formatting_test.exs` — price/plan formatting
- `test/haul/sortable_test.exs` — list manipulation
- `test/haul/billing_test.exs` — plan logic (can?/2, plan_features/1)
- `test/haul/ai/message_test.exs` — message transformations
- `test/haul/ai/error_classifier_test.exs` — error classification

**Pattern:** No setup block. Inline test data. `async: true`.

### LiveView Event Helpers (Tier 1 for LiveView callbacks)

Use `Haul.Test.LiveHelpers` to test `handle_event/3` and `handle_info/2` callbacks without mounting a LiveView process. This avoids the ~30-50ms mount overhead per test.

```elixir
defmodule HaulWeb.App.OnboardingLiveUnitTest do
  use ExUnit.Case, async: true

  import Haul.Test.LiveHelpers

  test "next increments step" do
    socket = build_socket(%{step: 1})
    assert {:noreply, socket} = apply_event(OnboardingLive, "next", %{}, socket)
    assert socket.assigns.step == 2
  end

  test "go_live appends finalization message" do
    socket = build_socket(%{finalized?: false, messages: []})
    assert {:noreply, socket} = apply_event(ChatLive, "go_live", %{}, socket)
    assert socket.assigns.finalized? == true
    assert length(socket.assigns.messages) == 1
  end
end
```

**When to use:**
- Callbacks that only update assigns (arithmetic, toggles, list manipulation)
- Guard logic in handle_event (empty input, rate limiting guards, state checks)
- handle_info callbacks that process async results (AI chunks, provisioning results)

**When NOT to use (keep full mount tests):**
- Tests that assert on rendered HTML (`assert html =~ "..."`)
- Tests that verify navigation (`assert_redirect`, `assert_patch`)
- Tests that exercise auth, tenant resolution, or plug pipeline
- Callbacks that call Ash/DB operations, file I/O, or external services
- Callbacks that use `consume_uploaded_entries` or `cancel_upload`

**Codebase examples:**
- `test/haul_web/live/app/onboarding_live_unit_test.exs` — step navigation (next/back/goto)
- `test/haul_web/live/chat_live_unit_test.exs` — input, toggle, send_message guards, handle_info callbacks

## Tier 2: Resource Tests

Test Ash resource actions, validations, relationships, and policies. Requires DB but no HTTP layer.

```elixir
defmodule Haul.Content.ServiceTest do
  use Haul.DataCase, async: false

  alias Haul.Test.Factories

  setup do
    company = Factories.build_company()
    tenant = Factories.provision_tenant(company)
    on_exit(fn -> Factories.cleanup_all_tenants() end)
    %{tenant: tenant}
  end

  test "add creates a service", %{tenant: tenant} do
    service = Factories.build_service(tenant, %{name: "Junk Removal"})
    assert service.name == "Junk Removal"
  end
end
```

**Codebase examples:**
- `test/haul/content/service_test.exs` — CRUD + ordering
- `test/haul/content/page_test.exs` — create/edit with markdown
- `test/haul/accounts/user_test.exs` — registration, sign-in
- `test/haul/tenant_isolation_test.exs` — cross-tenant access denied
- `test/haul/ai/provisioner_test.exs` — resource creation from AI

**Pattern:** Setup creates company + tenant. `on_exit` drops schemas. `async: false`.

## Tier 3: Integration Tests

Test HTTP controllers, LiveView mounts/events, and plug pipelines. Full request/response cycle.

```elixir
defmodule HaulWeb.App.BillingLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> cleanup_tenants() end)
  end

  test "renders billing page", %{conn: conn} do
    ctx = create_authenticated_context()
    conn = log_in_user(conn, ctx)
    {:ok, _view, html} = live(conn, ~p"/app/billing")
    assert html =~ "Billing"
  end
end
```

**Codebase examples:**
- `test/haul_web/controllers/page_controller_test.exs` — landing page content
- `test/haul_web/live/app/billing_live_test.exs` — plan cards + upgrade flow
- `test/haul_web/live/booking_live_test.exs` — form rendering
- `test/haul_web/smoke_test.exs` — all public routes render

**Pattern:** ConnCase helpers for auth. `live/2` + `render_click/3` for LiveView. `async: false`.

## Factory Usage

Factories live in `test/support/factories.ex`. Two categories:

**Account-level (used in Tier 2 & 3 setup):**
- `Factories.build_company(attrs \\ %{})` — creates a Company
- `Factories.provision_tenant(company)` — provisions schema, returns tenant string
- `Factories.build_user(tenant, attrs \\ %{})` — registers user, returns `%{user, token}`
- `Factories.build_authenticated_context(attrs \\ %{})` — company + tenant + user + token

**Resource-level (used in test bodies):**
- `Factories.build_service(tenant, attrs \\ %{})` — Service with defaults
- `Factories.build_page(tenant, attrs \\ %{})` — Page with markdown
- `Factories.build_booking_job(tenant, attrs \\ %{})` — Job in :lead state

All resource factories use `authorize?: false` to bypass policies. Test policies explicitly in separate tests.

## setup_all vs setup

- **`setup`** — runs before each test. Use for tenant creation/cleanup. Default choice.
- **`setup_all`** — runs once per module. Use when setup is expensive and tests are read-only (or tolerate shared mutations). Must be `async: false`.

Most tests use `setup`. Prefer `setup` unless profiling shows the per-test cost is a bottleneck.

### setup_all pattern for ConnCase

When tests share expensive setup (tenant provisioning, content seeding, admin creation):

```elixir
setup_all do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

  # Pre-cleanup: remove stale data from prior runs
  Haul.Test.Factories.cleanup_all_tenants()

  # Create shared state — committed via :auto mode
  ctx = Haul.Test.Factories.build_authenticated_context()
  Haul.Content.Seeder.seed!(ctx.tenant)

  # Release connection — committed data persists, ConnCase sandbox works normally
  Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)

  %{ctx: ctx}
end

setup do
  %{conn: Phoenix.ConnTest.build_conn()}
end
```

Key rules:
- **Pre-cleanup, not on_exit** — clean stale data at the start of setup_all. Avoid on_exit with `mode(:auto)` as it can race with the next module's sandbox setup.
- **`checkin` after data creation** — releases the :auto connection cleanly. ConnCase's per-test sandbox setup then works normally.
- **Use factories with unique names** — `Factories.build_authenticated_context()` generates unique slugs. Avoid `create_authenticated_context()` (hardcoded "Test Co") in setup_all.
- **Conn per test** — always create `conn` in per-test `setup`, never share it across tests.

Examples: `page_controller_test.exs`, `onboarding_live_test.exs`, `accounts_live_test.exs`.

## When async: true Is Safe

Use `async: true` when the test:
1. Uses only process-local state (process dictionary, process-keyed ETS)
2. Does not call `Application.put_env/3` for config other tests read
3. Does not use `cleanup_tenants/0` (global) — use `cleanup_tenant/1` (scoped) instead
4. Does not depend on test ordering or shared mutable state

**Tier 1** tests are always async. **Tier 2 and 3** tests can be async if they follow the process-local patterns below.

## Process-Local Shared State

Shared ETS state (rate limiter, sandboxes) must be scoped per-test to enable `async: true`.

### Rate limiter (process-local keys)

In test mode, `Haul.RateLimiter.check_rate/3` wraps ETS keys with the test process PID via the `$callers` ancestry chain. Each test's rate limit entries are isolated.

```elixir
# In test mode, key becomes {test_pid, original_key}
# LiveView processes find the test PID via $callers[0]
RateLimiter.check_rate({:signup, ip}, 5, 3600)
# ETS key: {test_pid, {:signup, ip}}
```

`clear_rate_limits/0` in ConnCase deletes only entries for `self()` (the current test process). Stale entries from other tests accumulate but don't affect lookups since keys are PID-scoped.

### ChatSandbox ($callers ancestry)

`Haul.AI.Chat.Sandbox` stores overrides in ETS keyed by `{pid, :response}` / `{pid, :error}`. Lookups walk `[self() | Process.get(:"$callers", [])]` to find overrides from the test process. Already safe for `async: true` — no changes needed.

### Making new shared state async-safe

When adding new ETS-based state that tests interact with:

1. **Key by test PID:** Wrap keys with `hd(Process.get(:"$callers", [self()]))` to scope entries per-test
2. **Use compile-time branching:** `if Mix.env() == :test` for the wrapping logic — zero production overhead
3. **Scoped cleanup:** Delete entries matching `{self(), :_}`, not `delete_all_objects`
4. **Prefer process dictionary** when cross-process lookup isn't needed (simpler, auto-cleanup)

## Concurrency Groups (Shared Tenant Pool)

ExUnit concurrency groups (Elixir 1.18+) let test files share a tenant while running in parallel with other groups. Tests in the same group run serially; different groups run concurrently.

### How to use

```elixir
# Opt in with async: true + group:
use HaulWeb.ConnCase, async: true, group: :pool_a
# or
use Haul.DataCase, async: true, group: :pool_a
```

The test context automatically includes `%{company, tenant, user, token}` (and `conn` for ConnCase) from the pre-provisioned pool tenant.

### Available groups

| Group | Tenant schema | Company slug |
|-------|---------------|--------------|
| `:pool_a` | `tenant___pool_a__` | `__pool_a__` |
| `:pool_b` | `tenant___pool_b__` | `__pool_b__` |
| `:pool_c` | `tenant___pool_c__` | `__pool_c__` |

### When to use

- **Use groups** when tests need DB writes in a shared tenant and can run serially within a group (e.g., LiveView tests that modify content)
- **Use `async: true`** (no group) when tests use their own tenant or the shared operator tenant and are fully independent
- **Use `async: false`** when tests need global state that can't be scoped (rare)

### How it works

1. `test_helper.exs` calls `Haul.Test.TenantPool.provision!(count: 3)` at suite start
2. Each pool tenant is cloned from `SchemaTemplate` (~5-15ms) with a pre-registered user
3. `DataCase.setup_sandbox/1` detects group tags and uses `shared: true` sandbox mode
4. `DataCase.pool_context/1` returns the tenant context for the group
5. ConnCase/DataCase `setup` callbacks merge pool context into the test context
6. Pool schemas are dropped in `ExUnit.after_suite`

### Important notes

- Tests in a group share the same tenant — mutations are visible to later tests in the group
- Create test data with unique identifiers, don't rely on "the only record"
- Balance test files across groups for optimal parallelism
- Pool provisioning adds ~45ms to suite startup (3 × ~15ms clone)

## Anti-Patterns

**Test at Tier 3 but only checks data:**
If your LiveView test creates a record and then asserts on the record (not the HTML), drop to Tier 2. Only use Tier 3 when you need to verify rendering or user interaction.

**Test at Tier 2 but doesn't use the DB:**
If your DataCase test only calls pure functions and never hits Ash/Ecto, drop to Tier 1. You'll get `async: true` and faster execution.

**Inline company/tenant setup instead of factories:**
Use `Factories.build_company()` and `Factories.provision_tenant()`. Don't duplicate the Ash changeset calls in every test file.

**Missing on_exit cleanup:**
Every test that provisions a tenant must drop it in `on_exit`. Use `Factories.cleanup_all_tenants()`. Without this, schemas accumulate and slow down the test database.

**Using async: true with DB tests:**
Tenant schema creation and cleanup are not safe for concurrent execution. All DB tests must use `async: false`.

## Adapter Switching

External service calls (Stripe, Twilio, Anthropic, Google Places, Fly) are dispatched through compile-time adapters. In test and dev, sandbox adapters replace real implementations.

### How it works

Each adapter dispatch module binds its adapter at compile time:

```elixir
# lib/haul/payments.ex
@adapter Application.compile_env(:haul, :payments_adapter, Haul.Payments.Sandbox)

def create_intent(params), do: @adapter.create_intent(params)
```

`Application.compile_env` reads from config at compile time and embeds the module as a constant. The adapter cannot change at runtime — the compiled BEAM bytecode contains the adapter module reference directly.

### Environment matrix

| Adapter | test / dev | prod |
|---------|:----------:|:----:|
| SMS | `Haul.SMS.Sandbox` | `Haul.SMS.Twilio` |
| Payments | `Haul.Payments.Sandbox` | `Haul.Payments.Stripe` |
| Billing | `Haul.Billing.Sandbox` | `Haul.Billing.Stripe` |
| AI | `Haul.AI.Sandbox` | `Haul.AI.Baml` |
| Chat | `Haul.AI.Chat.Sandbox` | `Haul.AI.Chat.Anthropic` |
| Places | `Haul.Places.Sandbox` | `Haul.Places.Google` |
| Certs | `Haul.Domains.Sandbox` | `Haul.Domains.FlyApi` |

- **Base defaults** (`config/config.exs`): all 7 adapters → Sandbox
- **Test** (`config/test.exs`): explicitly sets all 7 → Sandbox (redundant but clear)
- **Dev** (`config/dev.exs`): inherits Sandbox from base
- **Prod** (`config/prod.exs`): all 7 → production implementations
- **Runtime** (`config/runtime.exs`): sets API keys/secrets only, no adapter modules

### Adding a new adapter

1. **Define a behaviour** in the dispatch module (e.g., `@callback` in `lib/haul/foo.ex`)
2. **Create the production adapter** (e.g., `lib/haul/foo/bar_api.ex`) implementing the behaviour
3. **Create the sandbox adapter** (e.g., `lib/haul/foo/sandbox.ex`) implementing the behaviour with deterministic responses and optional per-test overrides via `Process.get/put`
4. **Add `@adapter Application.compile_env(:haul, :foo_adapter, Haul.Foo.Sandbox)`** in the dispatch module
5. **Set config entries:**
   - `config/config.exs`: `config :haul, :foo_adapter, Haul.Foo.Sandbox`
   - `config/test.exs`: `config :haul, :foo_adapter, Haul.Foo.Sandbox`
   - `config/prod.exs`: `config :haul, :foo_adapter, Haul.Foo.BarApi`
6. **Add API keys** to `config/runtime.exs` (runtime only, not adapter selection)

### Recompilation

`compile_env` triggers automatic recompilation when config changes. After editing any `config/*.exs` file, `mix compile` detects the change and recompiles affected modules. If compilation seems stale, run `mix compile --force`.

### Runtime config vs compile-time config

- **Compile-time** (`compile_env`): adapter module selection — which implementation to use
- **Runtime** (`get_env`): API keys, secrets, feature gates, operator config — values that vary per deployment

Do not put adapter selection in `config/runtime.exs`. `compile_env` cannot see runtime config, so the adapter would silently fall back to the default (Sandbox).

## Mock the Boundary, Not Ash

Ash resource operations (create, read, update, destroy) should always hit the real database in tests via the Ecto SQL.Sandbox. Mocking Ash calls fights the framework — tests pass while production breaks because constraint checks, policy enforcement, and changeset validations are skipped.

**Mock only at external service boundaries:**

| Boundary | Sandbox | Isolation Pattern |
|----------|---------|-------------------|
| AI/LLM extraction | `Haul.AI.Sandbox` | `Process.put/get` — per-process |
| Chat streaming | `Haul.AI.Chat.Sandbox` | ETS keyed by caller PID + `$callers` ancestry |
| SMS (Twilio) | `Haul.SMS.Sandbox` | `send(self(), {:sms_sent, msg})` — per-process |
| Email (SMTP) | `Swoosh.Adapters.Test` | Per-process (Swoosh built-in) |
| Payments (Stripe) | `Haul.Payments.Sandbox` | `Process.put/get` — per-process |
| Billing (Stripe) | `Haul.Billing.Sandbox` | `Process.put/get` — per-process |
| Places (Google) | `Haul.Places.Sandbox` | `Process.put/get` — per-process |
| Certs (Fly API) | `Haul.Domains.Sandbox` | Stateless (constant returns) |
| File storage | `Haul.Storage.Local` | Local filesystem (runtime config) |

### Process isolation patterns

**Same-process (most sandboxes):** Use `Process.put/get` for overrides. The override lives in the test process dictionary and is automatically cleaned up when the process exits. This is inherently safe for `async: true`.

**Cross-process (`Chat.Sandbox`):** Chat streaming spawns a Task that sends chunks to a LiveView process. The sandbox uses ETS keyed by caller PID and walks the `$callers` ancestry chain (same mechanism as `Ecto.Adapters.SQL.Sandbox`) to find the test process's overrides from child processes.

**Stateless (`Domains.Sandbox`):** Returns constant values with no per-test overrides. Always safe for `async: true`.

### Rules

1. **Never mock Ash.** Don't mock `Ash.read!`, `Ash.create!`, `Ash.update!`, or `Ash.get`. These should hit the real sandboxed database. Ash validations, constraints, and policies are the system's correctness guarantees.
2. **Mock at the adapter boundary.** The 7 compile-time adapters and Swoosh cover all external API calls. If you add a new external service, follow the adapter pattern (see "Adding a new adapter" above).
3. **Keep one integration test per module.** Even when orchestration tests use sandbox adapters for external calls, keep at least one test that exercises the full stack (DB + adapter) to catch wiring issues.
4. **Use `Factories.cleanup_all_tenants/0` for schema cleanup.** Don't inline the `information_schema` query — the factory version tolerates concurrent cleanup and excludes the shared test tenant.
