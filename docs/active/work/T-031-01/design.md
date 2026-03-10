# T-031-01 Design: compile-env-adapters

## Decision: Module attribute via `Application.compile_env`

### Approach

Replace `Application.get_env` adapter lookups with `@adapter Application.compile_env(...)` module attributes. Move production adapter selections from `runtime.exs` to `prod.exs` so they're visible at compile time.

### Why This Works

Adapters are determined by build environment (dev/test/prod), not by runtime state. The same binary always uses the same adapter. Moving adapter selection to compile time eliminates per-call ETS reads and makes the dispatch zero-cost.

### Config Migration

**Add to `prod.exs`:**
```elixir
config :haul, :payments_adapter, Haul.Payments.Stripe
config :haul, :billing_adapter, Haul.Billing.Stripe
config :haul, :sms_adapter, Haul.SMS.Twilio
config :haul, :places_adapter, Haul.Places.Google
config :haul, :cert_adapter, Haul.Domains.FlyApi
config :haul, :ai_adapter, Haul.AI.Baml
config :haul, :chat_adapter, Haul.AI.Chat.Anthropic
```

**Remove from `runtime.exs`:**
- All `config :haul, :*_adapter` lines
- Keep API keys, secrets, and other runtime config intact
- Keep `:chat_available` flag (genuine runtime decision)

### Module Pattern

Each module becomes:
```elixir
@adapter Application.compile_env(:haul, :ai_adapter, Haul.AI.Sandbox)

def call_function(name, args) do
  @adapter.call_function(name, args)
end
```

Remove `defp adapter` private functions and inline adapter lookups.

### Special Cases

1. **`Haul.AI.Chat.configured?/0`** — keeps `Application.get_env(:haul, :chat_available, true)`. This is a runtime feature flag, not adapter dispatch.

2. **`Haul.Billing.price_id/1`** — keeps `Application.get_env` for Stripe price IDs. These are set from env vars in runtime.exs and are genuinely runtime values.

3. **Places/Domains in dev** — currently runtime.exs sets real adapters in dev when API keys are present. With compile_env, dev always uses Sandbox. Devs who want real APIs in dev can add overrides to `dev.exs` (local, gitignored override). This is a minor behavioral change but the correct one — dev should default to sandbox.

### Alternatives Considered

**A. Keep runtime.exs, use `Application.get_env` (status quo)**
- Pro: Conditional adapter selection based on API key presence
- Con: Per-call ETS read, the whole point of this ticket is to eliminate it
- Rejected

**B. Move to compile_env but keep runtime.exs conditional logic**
- Pro: No config restructuring needed
- Con: Boot-time mismatch errors when runtime.exs overrides compile_env values
- Rejected: fundamentally incompatible with compile_env

**C. compile_env with prod.exs adapter selections (chosen)**
- Pro: Zero-cost dispatch, clear per-environment adapter config
- Con: Loses conditional "only enable if API key present" logic in prod
- Accepted: In production, API keys should always be present. Missing keys cause adapter errors at call time, which is the correct failure mode.

### Risk Assessment

Low risk. This is mechanical: move config lines, replace get_env with compile_env, remove private functions. All 845+ tests run with sandbox adapters set at compile time (test.exs). Production adapters just need their config moved from runtime.exs to prod.exs.
