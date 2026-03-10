# T-031-01 Structure: compile-env-adapters

## Files Modified

### Config (2 files)

**`config/prod.exs`** — Add production adapter selections (7 lines)
```
+ config :haul, :ai_adapter, Haul.AI.Baml
+ config :haul, :chat_adapter, Haul.AI.Chat.Anthropic
+ config :haul, :payments_adapter, Haul.Payments.Stripe
+ config :haul, :billing_adapter, Haul.Billing.Stripe
+ config :haul, :sms_adapter, Haul.SMS.Twilio
+ config :haul, :places_adapter, Haul.Places.Google
+ config :haul, :cert_adapter, Haul.Domains.FlyApi
```

**`config/runtime.exs`** — Remove adapter selection lines, keep API keys/secrets
- Remove: `config :haul, :places_adapter, Haul.Places.Google` (line 71)
- Remove: `config :haul, :cert_adapter, Haul.Domains.FlyApi` (line 77)
- Remove: `config :haul, :ai_adapter, Haul.AI.Baml` (line 91)
- Remove: `config :haul, :chat_adapter, Haul.AI.Chat.Anthropic` (line 92)
- Remove: `config :haul, :payments_adapter, Haul.Payments.Stripe` (line 185)
- Remove: `config :haul, :billing_adapter, Haul.Billing.Stripe` (line 206)
- Remove: `config :haul, :sms_adapter, Haul.SMS.Twilio` (line 223)
- Keep: all API key configs, secrets, Twilio config, Stripe webhook config, etc.

### Source Modules (7 files)

Each follows the same transformation:

**`lib/haul/ai.ex`**
- Add: `@adapter Application.compile_env(:haul, :ai_adapter, Haul.AI.Sandbox)`
- Change: `adapter().call_function` → `@adapter.call_function`
- Remove: `defp adapter` function

**`lib/haul/payments.ex`**
- Add: `@adapter Application.compile_env(:haul, :payments_adapter, Haul.Payments.Sandbox)`
- Change: 3 `adapter().fn` calls → `@adapter.fn`
- Remove: `defp adapter` function

**`lib/haul/billing.ex`**
- Add: `@adapter Application.compile_env(:haul, :billing_adapter, Haul.Billing.Sandbox)`
- Change: 6 `adapter().fn` calls → `@adapter.fn`
- Remove: `defp adapter` function

**`lib/haul/sms.ex`**
- Add: `@adapter Application.compile_env(:haul, :sms_adapter, Haul.SMS.Sandbox)`
- Change: inline `Application.get_env` + local var → `@adapter.send_sms`
- Remove: local `adapter` variable assignment

**`lib/haul/places.ex`**
- Add: `@adapter Application.compile_env(:haul, :places_adapter, Haul.Places.Sandbox)`
- Change: inline `Application.get_env` + local var → `@adapter.autocomplete`
- Remove: local `adapter` variable assignment

**`lib/haul/domains.ex`**
- Add: `@cert_adapter Application.compile_env(:haul, :cert_adapter, Haul.Domains.Sandbox)`
- Change: 3 `cert_adapter().fn` calls → `@cert_adapter.fn`
- Remove: `defp cert_adapter` function

**`lib/haul/ai/chat.ex`**
- Add: `@adapter Application.compile_env(:haul, :chat_adapter, Haul.AI.Chat.Sandbox)`
- Change: 2 `adapter().fn` calls → `@adapter.fn`
- Remove: `defp adapter` function
- Keep: `Application.get_env(:haul, :chat_available, true)` in `configured?/0` (runtime flag)

## Files NOT Modified

- `config/config.exs` — defaults already correct (all Sandbox)
- `config/test.exs` — already sets all adapters at compile time
- `config/dev.exs` — inherits Sandbox defaults, correct for dev
- Adapter implementations (Sandbox, Stripe, Twilio, etc.) — no changes needed
- Tests — no changes needed (already use compile-time Sandbox config)

## Ordering

1. Config changes first (prod.exs then runtime.exs)
2. Source modules in any order (independent of each other)
3. Run tests after all changes
