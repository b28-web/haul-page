defmodule Haul.Payments.Sandbox do
  @moduledoc """
  Sandbox payment adapter for dev/test. Returns deterministic canned
  responses and optionally notifies the calling process for test assertions.
  """

  @behaviour Haul.Payments

  @impl true
  def create_payment_intent(%{amount: amount, currency: currency} = params) do
    result = %{
      id: "pi_sandbox_#{System.unique_integer([:positive])}",
      object: "payment_intent",
      amount: amount,
      currency: currency,
      status: "requires_payment_method",
      client_secret: "pi_sandbox_secret_#{System.unique_integer([:positive])}",
      metadata: Map.get(params, :metadata, %{})
    }

    notify({:payment_intent_created, result})
    {:ok, result}
  end

  def create_payment_intent(_params) do
    {:error, :missing_required_params}
  end

  @impl true
  def retrieve_payment_intent(id) do
    result = %{
      id: id,
      object: "payment_intent",
      amount: 5000,
      currency: "usd",
      status: "succeeded",
      client_secret: "#{id}_secret",
      metadata: %{}
    }

    notify({:payment_intent_retrieved, result})
    {:ok, result}
  end

  @impl true
  def verify_webhook_signature(payload, _signature, _secret) do
    case Jason.decode(payload) do
      {:ok, event} -> {:ok, event}
      {:error, _} -> {:error, :invalid_payload}
    end
  end

  defp notify(message) do
    if pid = Process.get(:payments_sandbox_pid) do
      send(pid, message)
    end
  end
end
