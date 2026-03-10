---
id: S-031
title: resolve-adapters-at-boot
status: open
epics: [E-016]
---

## Resolve Adapters at Boot

7 modules use the GoF Strategy pattern: call `Application.get_env` on every function invocation to look up which adapter module to use. This is a per-request singleton lookup. The Erlang way: resolve once at compile time or boot time, not on every call.

## The pattern today

```elixir
# In every public function:
defp adapter, do: Application.get_env(:haul, __MODULE__)[:adapter] || Haul.Payments.Stripe

def create_payment_intent(params) do
  adapter().create_payment_intent(params)  # ETS read on every call
end
```

## Affected modules (7)

1. `Haul.AI` — 1 callback, sandbox/real
2. `Haul.Payments` — 3 callbacks, sandbox/stripe
3. `Haul.Billing` — 6 callbacks, sandbox/stripe
4. `Haul.SMS` — 1 callback, sandbox/twilio
5. `Haul.Places` — 1 callback, sandbox/google
6. `Haul.Domains` (cert adapter) — 3 callbacks, sandbox/fly
7. `Haul.AI.Chat` — 2 callbacks, sandbox/anthropic

## Target pattern

```elixir
# Resolved once at compile time:
@adapter Application.compile_env(:haul, [__MODULE__, :adapter], Haul.Payments.Stripe)

def create_payment_intent(params) do
  @adapter.create_payment_intent(params)  # No runtime lookup
end
```

Or for cases where runtime switching is needed (unlikely outside tests):

```elixir
# Resolved once at GenServer init:
def init(_) do
  adapter = Application.get_env(:haul, __MODULE__)[:adapter]
  {:ok, %{adapter: adapter}}
end
```

## Tickets

- T-031-01: compile-env-adapters — switch all 7 modules from `Application.get_env` to `Application.compile_env` with module attributes
- T-031-02: verify-test-switching — ensure sandbox adapters still work in test config (compile_env reads from config/test.exs at compile time, which is where sandboxes are already configured)

## Acceptance criteria

- Zero `Application.get_env` calls in adapter dispatch hot paths
- All 7 modules use `@adapter` module attribute or equivalent compile-time resolution
- Sandbox adapters work in `mix test` (config/test.exs sets them at compile time)
- Production adapters work in `mix phx.server` (config/runtime.exs or config/prod.exs)
- No behavior change — just when the lookup happens
