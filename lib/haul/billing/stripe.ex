defmodule Haul.Billing.Stripe do
  @moduledoc """
  Production billing adapter. Wraps stripity_stripe SDK calls for
  customer and subscription management.
  """

  @behaviour Haul.Billing

  @impl true
  def create_customer(company) do
    params = %{
      name: Map.get(company, :name),
      metadata: %{company_id: Map.get(company, :id)}
    }

    case Stripe.Customer.create(params) do
      {:ok, customer} -> {:ok, customer.id}
      {:error, %Stripe.Error{} = error} -> {:error, error.message}
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def create_subscription(customer_id, price_id) do
    params = %{
      customer: customer_id,
      items: [%{price: price_id}]
    }

    case Stripe.Subscription.create(params) do
      {:ok, sub} ->
        {:ok,
         %{
           id: sub.id,
           status: sub.status,
           current_period_end: sub.current_period_end,
           customer: sub.customer
         }}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def cancel_subscription(subscription_id) do
    case Stripe.Subscription.cancel(subscription_id, %{}) do
      {:ok, sub} ->
        {:ok,
         %{
           id: sub.id,
           status: sub.status,
           current_period_end: sub.current_period_end,
           customer: sub.customer
         }}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def create_checkout_session(params) do
    checkout_params = %{
      mode: "subscription",
      customer: params.customer_id,
      line_items: [%{price: params.price_id, quantity: 1}],
      success_url: params.success_url,
      cancel_url: params.cancel_url
    }

    case Stripe.Checkout.Session.create(checkout_params) do
      {:ok, session} ->
        {:ok, %{id: session.id, url: session.url}}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def create_portal_session(customer_id, return_url) do
    params = %{customer: customer_id, return_url: return_url}

    case Stripe.BillingPortal.Session.create(params) do
      {:ok, session} ->
        {:ok, %{url: session.url}}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def update_subscription(subscription_id, params) do
    update_params = %{
      items: [%{price: params.price_id}]
    }

    case Stripe.Subscription.update(subscription_id, update_params) do
      {:ok, sub} ->
        {:ok,
         %{
           id: sub.id,
           status: sub.status,
           current_period_end: sub.current_period_end,
           customer: sub.customer
         }}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, error} ->
        {:error, error}
    end
  end
end
