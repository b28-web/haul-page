defmodule Haul.Payments do
  @moduledoc """
  Payment processing behaviour. Dispatches to the adapter configured via
  `config :haul, :payments_adapter`.

  Adapters:
  - `Haul.Payments.Stripe` — production, calls Stripe API via stripity_stripe
  - `Haul.Payments.Sandbox` — dev/test, returns canned responses
  """

  @type payment_intent_params :: %{
          required(:amount) => pos_integer(),
          required(:currency) => String.t(),
          optional(:metadata) => map()
        }

  @callback create_payment_intent(params :: payment_intent_params()) ::
              {:ok, map()} | {:error, term()}

  @callback retrieve_payment_intent(id :: String.t()) ::
              {:ok, map()} | {:error, term()}

  @callback verify_webhook_signature(
              payload :: String.t(),
              signature :: String.t(),
              secret :: String.t()
            ) :: {:ok, map()} | {:error, term()}

  @doc """
  Create a Stripe PaymentIntent. Delegates to the configured adapter.

  Params must include `:amount` (integer cents) and `:currency` (e.g. "usd").
  """
  def create_payment_intent(params) do
    adapter().create_payment_intent(params)
  end

  @doc """
  Retrieve a PaymentIntent by ID to verify its status server-side.
  """
  def retrieve_payment_intent(id) do
    adapter().retrieve_payment_intent(id)
  end

  @doc """
  Verify a Stripe webhook signature and parse the event payload.
  """
  def verify_webhook_signature(payload, signature, secret) do
    adapter().verify_webhook_signature(payload, signature, secret)
  end

  defp adapter do
    Application.get_env(:haul, :payments_adapter, Haul.Payments.Sandbox)
  end
end
