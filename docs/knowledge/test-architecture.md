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
- **`setup_all`** — runs once per module. Use when setup is expensive and tests are read-only. Must be `async: false`. Cleanup in `on_exit` inside `setup_all`.

Most tests use `setup`. Prefer `setup` unless profiling shows the per-test cost is a bottleneck.

## When async: true Is Safe

Use `async: true` only when the test:
1. Does not touch the database (no Ash actions, no Ecto queries)
2. Does not use GenServer, ETS, or Agent state
3. Does not depend on application config that other tests might change
4. Does not use shared fixtures that could race

In practice: Tier 1 tests are async. Tier 2 and 3 tests are not.

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
