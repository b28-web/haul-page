# T-008-01 Structure: Stripe Setup

## Files to Create

### `lib/haul/payments.ex`
Behaviour + dispatcher module (mirrors `Haul.SMS` pattern).

```elixir
defmodule Haul.Payments do
  @callback create_payment_intent(params :: map()) :: {:ok, map()} | {:error, term()}
  @callback verify_webhook_signature(payload :: String.t(), signature :: String.t(), secret :: String.t()) :: {:ok, map()} | {:error, term()}

  def create_payment_intent(params), do: adapter().create_payment_intent(params)
  def verify_webhook_signature(payload, signature, secret), do: adapter().verify_webhook_signature(payload, signature, secret)

  defp adapter, do: Application.get_env(:haul, :payments_adapter, Haul.Payments.Sandbox)
end
```

### `lib/haul/payments/stripe.ex`
Production adapter — thin wrapper around stripity_stripe SDK.

- `create_payment_intent/1` → `Stripe.PaymentIntent.create/1`
- `verify_webhook_signature/3` → `Stripe.Webhook.construct_event/3`

### `lib/haul/payments/sandbox.ex`
Dev/test adapter — returns deterministic canned responses.

- `create_payment_intent/1` → `{:ok, %{id: "pi_sandbox_...", ...}}`
- `verify_webhook_signature/3` → `{:ok, Jason.decode!(payload)}`
- Sends `{:payment_intent_created, params}` to calling process (like SMS.Sandbox)

### `test/haul/payments_test.exs`
- Test `create_payment_intent/1` via Sandbox adapter (returns struct-like map)
- Test `verify_webhook_signature/3` via Sandbox adapter
- Validate required params (amount, currency)

## Files to Modify

### `mix.exs`
Add `{:stripity_stripe, "~> 3.2"}` to deps.

### `config/config.exs`
```elixir
config :haul, :payments_adapter, Haul.Payments.Sandbox
config :stripity_stripe, api_key: ""
```

### `config/runtime.exs`
In the `config_env() == :prod` block:
```elixir
if stripe_key = System.get_env("STRIPE_SECRET_KEY") do
  config :haul, :payments_adapter, Haul.Payments.Stripe
  config :stripity_stripe, api_key: stripe_key

  if webhook_secret = System.get_env("STRIPE_WEBHOOK_SECRET") do
    config :stripity_stripe, signing_secret: webhook_secret
  end
end
```

### `config/test.exs`
```elixir
config :haul, :payments_adapter, Haul.Payments.Sandbox
config :stripity_stripe, api_key: "sk_test_fake"
```

## Files NOT Changed
- No Ash domain/resource changes
- No migration
- No router changes
- No LiveView changes

## Module Boundaries
- `Haul.Payments` is a standalone context module, not an Ash domain
- It doesn't depend on any Ash resources (Job, Company)
- Future tickets (T-008-02) will call `Haul.Payments` from LiveView
- Future tickets (T-008-03) will use `verify_webhook_signature` in a controller
