---
id: T-031-01
story: S-031
title: compile-env-adapters
type: task
status: open
priority: medium
phase: done
depends_on: []
---

## Context

7 modules call `Application.get_env` on every function invocation to look up which adapter to dispatch to. This is a runtime ETS read per call. Since adapters are determined by config environment (dev/test/prod) and don't change at runtime, they should be resolved at compile time.

## Acceptance Criteria

- Convert all 7 adapter modules from `Application.get_env` to `Application.compile_env`:
  1. `Haul.AI` — `@adapter Application.compile_env(:haul, [Haul.AI, :adapter], Haul.AI.BamlAdapter)`
  2. `Haul.Payments` — `@adapter Application.compile_env(:haul, [Haul.Payments, :adapter], Haul.Payments.Stripe)`
  3. `Haul.Billing` — `@adapter Application.compile_env(:haul, [Haul.Billing, :adapter], Haul.Billing.Stripe)`
  4. `Haul.SMS` — `@adapter Application.compile_env(:haul, [Haul.SMS, :adapter], Haul.SMS.Twilio)`
  5. `Haul.Places` — `@adapter Application.compile_env(:haul, [Haul.Places, :adapter], Haul.Places.Google)`
  6. `Haul.Domains` (cert) — `@cert_adapter Application.compile_env(:haul, [Haul.Domains, :cert_adapter], Haul.Domains.FlyCert)`
  7. `Haul.AI.Chat` — `@adapter Application.compile_env(:haul, [Haul.AI.Chat, :adapter], Haul.AI.Chat.Anthropic)`
- Replace `adapter().function(args)` with `@adapter.function(args)` in all public functions
- Remove private `defp adapter` functions
- Verify defaults match current production config
- All 845+ tests pass (config/test.exs already sets sandbox adapters at compile time)

## Implementation Notes

- `Application.compile_env` reads from config at compile time and embeds the value as a module attribute
- If config changes, the module must be recompiled (Mix handles this automatically for config/*.exs changes)
- This is a safe, mechanical refactor — the adapter modules and their interfaces don't change
- Also check for `Application.get_env` in adapter implementations themselves (e.g., API key lookups in Stripe/Anthropic modules) — those may need to stay as runtime lookups if they read from `config/runtime.exs`
