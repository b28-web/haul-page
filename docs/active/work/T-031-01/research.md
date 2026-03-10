# T-031-01 Research: compile-env-adapters

## Current State

7 modules use `Application.get_env` at runtime to resolve which adapter to dispatch to. All follow the same pattern: a private `defp adapter` function (or inline call) that reads config on every invocation.

### Adapter Inventory

| Module | Config Key | Default | Prod Adapter | Pattern |
|--------|-----------|---------|-------------|---------|
| `Haul.AI` | `:ai_adapter` | `Haul.AI.Sandbox` | `Haul.AI.Baml` | private fn |
| `Haul.Payments` | `:payments_adapter` | `Haul.Payments.Sandbox` | `Haul.Payments.Stripe` | private fn |
| `Haul.Billing` | `:billing_adapter` | `Haul.Billing.Sandbox` | `Haul.Billing.Stripe` | private fn |
| `Haul.SMS` | `:sms_adapter` | `Haul.SMS.Sandbox` | `Haul.SMS.Twilio` | inline |
| `Haul.Places` | `:places_adapter` | `Haul.Places.Sandbox` | `Haul.Places.Google` | inline |
| `Haul.Domains` | `:cert_adapter` | `Haul.Domains.Sandbox` | `Haul.Domains.FlyApi` | private fn |
| `Haul.AI.Chat` | `:chat_adapter` | `Haul.AI.Chat.Sandbox` | `Haul.AI.Chat.Anthropic` | private fn |

### Two Dispatch Patterns

**Private function pattern** (5 modules: AI, Payments, Billing, Domains, AI.Chat):
```elixir
defp adapter, do: Application.get_env(:haul, :key, Default)
# called as adapter().function(args)
```

**Inline pattern** (2 modules: SMS, Places):
```elixir
adapter = Application.get_env(:haul, :key, Default)
adapter.function(args)
```

### Config Layering

- `config.exs` — sets all adapters to Sandbox (base defaults)
- `test.exs` — explicitly re-sets all adapters to Sandbox (redundant but clear)
- `dev.exs` — no adapter config (inherits Sandbox from config.exs)
- `prod.exs` — no adapter config (adapters set in runtime.exs)
- `runtime.exs` — conditionally sets production adapters based on env vars

### Critical Finding: runtime.exs Sets Production Adapters

Currently, production adapters are set in `runtime.exs` conditionally:
- Payments/Billing/SMS: inside `if config_env() == :prod` block, conditional on API keys
- Places/Domains: outside prod block, conditional on API keys (applies to all envs)
- AI/Chat: outside prod block, conditional on ANTHROPIC_API_KEY + `config_env() != :test` guard

`Application.compile_env` reads at compile time only (from config.exs/dev.exs/test.exs/prod.exs). Values set in `runtime.exs` are NOT visible to `compile_env`. A boot-time check will error if the runtime value differs from the compiled value.

This means moving to `compile_env` requires moving adapter selections from `runtime.exs` to `prod.exs`.

### Non-Adapter get_env Calls (Must Stay Runtime)

- `Haul.AI.Chat.configured?/0` — reads `:chat_available`, set conditionally in runtime.exs based on ANTHROPIC_API_KEY presence. Genuine runtime decision.
- `Haul.Billing.price_id/1` — reads `:stripe_price_pro`, `:stripe_price_business`, `:stripe_price_dedicated`. Set from env vars in runtime.exs. Must stay runtime.

### Existing compile_env Usage

- `HaulWeb.ChatLive` — `@max_messages`, `@extraction_debounce_ms` (compile-time constants)
- `HaulWeb.Router` — `dev_routes` gate

### Files to Modify

Source modules (7):
- `lib/haul/ai.ex`
- `lib/haul/payments.ex`
- `lib/haul/billing.ex`
- `lib/haul/sms.ex`
- `lib/haul/places.ex`
- `lib/haul/domains.ex`
- `lib/haul/ai/chat.ex`

Config files (2):
- `config/prod.exs` — add adapter selections
- `config/runtime.exs` — remove adapter selections
