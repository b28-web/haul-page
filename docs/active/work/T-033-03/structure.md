# T-033-03 Structure: Mock Service Layer

## Files Modified

### 1. `lib/haul/ai/chat/sandbox.ex` — Process-keyed isolation

**Current:** Global ETS table, `set_response/1` writes globally, `get_response/0` reads globally.

**After:** Dual-layer lookup: Process.put for same-process overrides, ETS keyed by caller PID for cross-process (streaming).

Public interface (unchanged):
- `set_response(response)` — sets override for calling process
- `set_error(error)` — sets error for calling process
- `clear_response()` — clears override
- `clear_error()` — clears error

Internal changes:
- `set_response/1` writes to `Process.put({__MODULE__, :response}, value)` AND `ETS insert({self(), :response}, value)`
- `get_response/0` checks `Process.get` first, falls back to ETS lookup by `self()`, then default
- `stream_message/3` receives pid — looks up that pid's entry in ETS (cross-process)
- `send_message/2` uses `Process.get` (same-process, no ETS needed)

### 2. `docs/knowledge/test-architecture.md` — Add mocking conventions

Add new section after "Adapter Switching":

**"Mock the Boundary, Not Ash"** section covering:
- Why Ash actions should hit real DB (constraint checks, policy enforcement)
- What qualifies as a mockable boundary (external APIs only)
- The 7+1 adapter inventory (7 compile-time + Swoosh)
- How to add test overrides in sandbox adapters
- Process isolation patterns (Process.put vs ETS)
- Rule: at least one integration test per module exercises the real service path

### 3. Worker test files — Migrate cleanup to Factories

Files to update (replace inline cleanup with `Factories.cleanup_all_tenants/0`):
- `test/haul/workers/check_dunning_grace_test.exs`
- `test/haul/workers/provision_cert_test.exs`
- `test/haul/workers/send_booking_email_test.exs`
- `test/haul/workers/send_booking_sms_test.exs`
- `test/haul/workers/provision_site_test.exs`
- `test/haul/ai/edit_applier_test.exs`
- `test/haul/ai/provisioner_test.exs`

Change: Replace the inline `on_exit` block that queries `information_schema.schemata` and drops schemas with `on_exit(fn -> Haul.Test.Factories.cleanup_all_tenants() end)`.

## Files NOT Modified

- No new files created (no new adapters needed — all boundaries covered)
- No changes to dispatch modules (Haul.Payments, Haul.SMS, etc.)
- No changes to production adapters
- No changes to config files
- No changes to test case modules (DataCase, ConnCase)
- No changes to test logic or assertions (worker tests still test the same things)

## Module Boundaries

```
Haul.AI.Chat.Sandbox (modified)
├── Process.put/get — same-process overrides (send_message)
├── ETS keyed by PID — cross-process overrides (stream_message)
└── Default response — fallback when no override set

docs/knowledge/test-architecture.md (modified)
└── New section: "Mock the Boundary, Not Ash"
```
