defmodule Haul.Billing.Sandbox do
  @moduledoc """
  Sandbox billing adapter for dev/test. Returns deterministic canned
  responses and optionally notifies the calling process for test assertions.
  """

  @behaviour Haul.Billing

  @impl true
  def create_customer(company) do
    customer_id = "cus_sandbox_#{System.unique_integer([:positive])}"
    notify({:customer_created, customer_id, company})
    {:ok, customer_id}
  end

  @impl true
  def create_subscription(customer_id, price_id) do
    result = %{
      id: "sub_sandbox_#{System.unique_integer([:positive])}",
      status: "active",
      current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
      customer: customer_id
    }

    notify({:subscription_created, result, price_id})
    {:ok, result}
  end

  @impl true
  def cancel_subscription(subscription_id) do
    result = %{
      id: subscription_id,
      status: "canceled",
      current_period_end: DateTime.utc_now() |> DateTime.to_unix(),
      customer: "cus_sandbox_0"
    }

    notify({:subscription_canceled, result})
    {:ok, result}
  end

  @impl true
  def create_checkout_session(params) do
    session_id = "cs_sandbox_#{System.unique_integer([:positive])}"

    result = %{
      id: session_id,
      url:
        "#{params.success_url}#{if String.contains?(params.success_url, "?"), do: "&", else: "?"}session_id=#{session_id}"
    }

    notify({:checkout_session_created, result, params})
    {:ok, result}
  end

  @impl true
  def create_portal_session(customer_id, return_url) do
    result = %{url: return_url}
    notify({:portal_session_created, result, customer_id})
    {:ok, result}
  end

  @impl true
  def update_subscription(subscription_id, params) do
    result = %{
      id: subscription_id,
      status: "active",
      current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
      customer: "cus_sandbox_0"
    }

    notify({:subscription_updated, result, params})
    {:ok, result}
  end

  defp notify(message) do
    if pid = Process.get(:billing_sandbox_pid) do
      send(pid, message)
    end
  end
end
