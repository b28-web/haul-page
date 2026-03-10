# T-033-03 Research: Mock Service Layer

## Current State of External Service Mocking

### The 7 compile-time adapters (all sandboxed in tests)

| # | Dispatch Module | Config Key | Sandbox | Production | Async-Safe |
|---|----------------|-----------|---------|-----------|------------|
| 1 | `Haul.Payments` | `:payments_adapter` | `Haul.Payments.Sandbox` | `Haul.Payments.Stripe` | Yes (Process.put) |
| 2 | `Haul.SMS` | `:sms_adapter` | `Haul.SMS.Sandbox` | `Haul.SMS.Twilio` | Yes (send to self()) |
| 3 | `Haul.Billing` | `:billing_adapter` | `Haul.Billing.Sandbox` | `Haul.Billing.Stripe` | Yes (Process.put) |
| 4 | `Haul.AI` | `:ai_adapter` | `Haul.AI.Sandbox` | `Haul.AI.Baml` | Yes (Process.put) |
| 5 | `Haul.AI.Chat` | `:chat_adapter` | `Haul.AI.Chat.Sandbox` | `Haul.AI.Chat.Anthropic` | **No (ETS global)** |
| 6 | `Haul.Places` | `:places_adapter` | `Haul.Places.Sandbox` | `Haul.Places.Google` | Yes (Process.put) |
| 7 | `Haul.Domains` | `:cert_adapter` | `Haul.Domains.Sandbox` | `Haul.Domains.FlyApi` | Yes (stateless) |

### Additional service boundaries

- **Email (Swoosh)** — `config :haul, Haul.Mailer, adapter: Swoosh.Adapters.Test` — process-isolated
- **Storage** — `Haul.Storage` uses runtime `get_env` with `:local` backend in tests — writes to tmp dir, not S3
- **PubSub** — `Phoenix.PubSub` is in-memory, not an external service — tests subscribe and assert_receive directly

### Config setup

All 7 adapters set in `config/config.exs` (defaults to Sandbox) and redundantly in `config/test.exs`. `config/prod.exs` sets production implementations. `config/runtime.exs` handles API keys only.

## ChatSandbox Async Safety Issue

`Haul.AI.Chat.Sandbox` uses a **global ETS table** (`__MODULE__` as table name). All operations are shared state:
- `set_response/1` writes to ETS globally
- `set_error/1` writes to ETS globally
- `get_response/0` reads from ETS globally
- No caller-key or process-keyed isolation

**Risk:** If two async tests both call `set_response/1`, they will overwrite each other. Currently not a problem because all chat tests use `async: false`, but this blocks future async unlock (T-033-05).

**All other sandboxes are async-safe:** They use either `Process.put/get` (scoped to test process), `send(self(), ...)` (scoped to test process), or are stateless (Domains.Sandbox returns constant values).

## Mock Candidate Tests from T-033-01 Audit

The audit identified 18 tests across 7 files as "mockable." Analysis:

| File | Tests | Audit Says | Reality |
|------|-------|-----------|---------|
| check_dunning_grace_test.exs | 3 | "Mock Company lookup + Ash.update!" | External calls: **none**. All Ash DB. |
| provision_cert_test.exs | 5 | "Mock Company lookup" | Cert adapter: **already sandboxed**. DB: Ash. |
| send_booking_email_test.exs | 3 | "Mock Job lookup" | Swoosh: **already sandboxed**. DB: Ash. |
| send_booking_sms_test.exs | 2 | "Mock Job lookup" | SMS: **already sandboxed**. DB: Ash. |
| edit_applier_test.exs | 3 | "Mock Ash reads" | AI: **already sandboxed**. DB: Ash. |
| provisioner_test.exs | 1 | "Mock validation" | AI: **already sandboxed**. DB: Ash. |
| provision_site_test.exs | 1 | "Mock enqueue" | All adapters: **already sandboxed**. |

**Key finding:** All external service boundaries are already covered by sandbox adapters. The audit's mock suggestions involve mocking Ash DB operations, which the ticket explicitly prohibits ("don't mock Ash resource calls").

## What the Worker Tests Actually Do

Each worker test:
1. **Setup:** Creates Company/Job via Ash actions (hits real sandboxed Postgres)
2. **Execute:** Calls `worker.perform(%Oban.Job{...})`
3. **Assert:** Checks DB state changes, process messages, or PubSub broadcasts

The external service calls within workers are already routed through sandbox adapters. The DB operations are intentionally real (per ticket: "Real DB for Ash actions").

## Tenant Schema Cleanup Pattern

All 7 test files manually build `on_exit` cleanup that queries `information_schema.schemata` and drops `tenant_%` schemas. This is the dominant setup cost (~200ms per test file). The factories module has `Factories.cleanup_all_tenants/0` but not all files use it.

## Gaps Found

1. **ChatSandbox async safety** — ETS global state prevents async: true
2. **Missing documentation** — test-architecture.md has adapter switching section but no explicit "mock the boundary, not Ash" convention
3. **Inconsistent cleanup** — Some test files use inline schema cleanup instead of `Factories.cleanup_all_tenants/0`
4. **No gaps in adapter coverage** — All 7 external service boundaries have working sandbox adapters
