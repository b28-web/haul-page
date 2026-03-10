# T-031-01 Review: compile-env-adapters

## Test Results

```
971 tests, 0 failures (1 excluded)
Finished in 91.7 seconds
```

Full suite passes. All 7 modules recompiled successfully with `compile_env`.

## Changes Summary

### Config files (2 modified)

**`config/prod.exs`** — Added 7 production adapter selections (compile-time):
- `:ai_adapter` → `Haul.AI.Baml`
- `:chat_adapter` → `Haul.AI.Chat.Anthropic`
- `:payments_adapter` → `Haul.Payments.Stripe`
- `:billing_adapter` → `Haul.Billing.Stripe`
- `:sms_adapter` → `Haul.SMS.Twilio`
- `:places_adapter` → `Haul.Places.Google`
- `:cert_adapter` → `Haul.Domains.FlyApi`

**`config/runtime.exs`** — Removed 7 adapter selection lines. All API keys, secrets, Twilio credentials, Stripe webhook secrets, and non-adapter config preserved. Comments updated to reflect that adapter selection is now compile-time.

### Source modules (7 modified)

Each module:
1. Added `@adapter Application.compile_env(...)` module attribute
2. Replaced `adapter().fn(args)` / inline get_env with `@adapter.fn(args)`
3. Removed `defp adapter` private function (or inline variable assignment)

Files: `lib/haul/ai.ex`, `lib/haul/payments.ex`, `lib/haul/billing.ex`, `lib/haul/sms.ex`, `lib/haul/places.ex`, `lib/haul/domains.ex`, `lib/haul/ai/chat.ex`

### Intentionally unchanged

- `Haul.AI.Chat.configured?/0` — keeps `Application.get_env(:haul, :chat_available, true)` because this is a runtime feature flag set conditionally in `runtime.exs` based on ANTHROPIC_API_KEY presence
- `Haul.Billing.price_id/1` — keeps `Application.get_env` for Stripe price IDs (set from env vars in runtime.exs)

## Test Coverage

No new tests needed. Existing 971 tests exercise all adapter dispatch paths through sandbox adapters. The refactor changes the dispatch mechanism (ETS read → compiled module attribute) without changing behavior.

## Open Concerns

1. **Dev workflow with real APIs**: Previously, setting e.g. `GOOGLE_PLACES_API_KEY` in dev would auto-switch to the real adapter via runtime.exs. Now dev always compiles with Sandbox. Developers who want real APIs in dev should add overrides to `config/dev.exs`. This is a minor behavioral change but the correct default — dev should use sandboxes.

2. **Production without API keys**: Previously, runtime.exs only enabled production adapters when API keys were present (graceful degradation). Now prod.exs always sets production adapters. If an API key is missing, the adapter will fail at call time with a clear error rather than silently falling back to Sandbox. This is the correct failure mode for production.
