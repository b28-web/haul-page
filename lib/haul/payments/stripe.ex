defmodule Haul.Payments.Stripe do
  @moduledoc """
  Production payment adapter. Wraps stripity_stripe SDK calls.
  """

  @behaviour Haul.Payments

  @impl true
  def create_payment_intent(%{amount: amount, currency: currency} = params) do
    stripe_params = %{
      amount: amount,
      currency: currency,
      metadata: Map.get(params, :metadata, %{})
    }

    case Stripe.PaymentIntent.create(stripe_params) do
      {:ok, intent} ->
        {:ok,
         %{
           id: intent.id,
           object: intent.object,
           amount: intent.amount,
           currency: intent.currency,
           status: intent.status,
           client_secret: intent.client_secret,
           metadata: intent.metadata
         }}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end

  def create_payment_intent(_params) do
    {:error, :missing_required_params}
  end

  @impl true
  def retrieve_payment_intent(id) do
    case Stripe.PaymentIntent.retrieve(id) do
      {:ok, intent} ->
        {:ok,
         %{
           id: intent.id,
           object: intent.object,
           amount: intent.amount,
           currency: intent.currency,
           status: intent.status,
           client_secret: intent.client_secret,
           metadata: intent.metadata
         }}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def verify_webhook_signature(payload, signature, secret) do
    case Stripe.Webhook.construct_event(payload, signature, secret) do
      {:ok, event} -> {:ok, event}
      {:error, error} -> {:error, error}
    end
  end
end
