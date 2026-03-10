defmodule Haul.Billing do
  @moduledoc """
  Subscription billing behaviour and feature gates. Dispatches subscription
  operations to the adapter configured via `config :haul, :billing_adapter`.

  Adapters:
  - `Haul.Billing.Stripe` — production, calls Stripe API via stripity_stripe
  - `Haul.Billing.Sandbox` — dev/test, returns canned responses
  """

  @callback create_customer(company :: map()) ::
              {:ok, String.t()} | {:error, term()}

  @callback create_subscription(customer_id :: String.t(), price_id :: String.t()) ::
              {:ok, map()} | {:error, term()}

  @callback cancel_subscription(subscription_id :: String.t()) ::
              {:ok, map()} | {:error, term()}

  @callback create_checkout_session(params :: map()) ::
              {:ok, map()} | {:error, term()}

  @callback create_portal_session(customer_id :: String.t(), return_url :: String.t()) ::
              {:ok, map()} | {:error, term()}

  @callback update_subscription(subscription_id :: String.t(), params :: map()) ::
              {:ok, map()} | {:error, term()}

  @adapter Application.compile_env(:haul, :billing_adapter, Haul.Billing.Sandbox)

  # -- Adapter dispatch --

  def create_customer(company), do: @adapter.create_customer(company)

  def create_subscription(customer_id, price_id),
    do: @adapter.create_subscription(customer_id, price_id)

  def cancel_subscription(subscription_id),
    do: @adapter.cancel_subscription(subscription_id)

  def create_checkout_session(params), do: @adapter.create_checkout_session(params)

  def create_portal_session(customer_id, return_url),
    do: @adapter.create_portal_session(customer_id, return_url)

  def update_subscription(subscription_id, params),
    do: @adapter.update_subscription(subscription_id, params)

  # -- Feature gates (pure functions, no adapter) --

  @feature_matrix %{
    starter: [],
    pro: [:sms_notifications, :custom_domain],
    business: [:sms_notifications, :custom_domain, :payment_collection, :crew_app],
    dedicated: [:sms_notifications, :custom_domain, :payment_collection, :crew_app]
  }

  @doc """
  Check if a company's subscription plan includes the given feature.

      Haul.Billing.can?(company, :sms_notifications)
      #=> true (if company.subscription_plan is :pro, :business, or :dedicated)
  """
  def can?(%{subscription_plan: plan}, feature) when is_atom(feature) do
    feature in plan_features(plan)
  end

  def can?(_, _), do: false

  @doc """
  Returns the list of features available for a given plan.
  """
  def plan_features(plan) when is_atom(plan) do
    Map.get(@feature_matrix, plan, [])
  end

  @doc """
  Returns all plan definitions with name, monthly price in cents, and features.
  """
  def plans do
    [
      %{id: :starter, name: "Starter", price_cents: 0, features: @feature_matrix[:starter]},
      %{id: :pro, name: "Pro", price_cents: 2900, features: @feature_matrix[:pro]},
      %{id: :business, name: "Business", price_cents: 7900, features: @feature_matrix[:business]},
      %{
        id: :dedicated,
        name: "Dedicated",
        price_cents: 14_900,
        features: @feature_matrix[:dedicated]
      }
    ]
  end

  @doc """
  Returns the configured Stripe Price ID for a paid plan.
  """
  def price_id(:pro), do: Application.get_env(:haul, :stripe_price_pro, "")
  def price_id(:business), do: Application.get_env(:haul, :stripe_price_business, "")
  def price_id(:dedicated), do: Application.get_env(:haul, :stripe_price_dedicated, "")
  def price_id(_), do: nil

  @doc """
  Reverse lookup: given a Stripe Price ID, returns the corresponding plan atom.
  Returns nil if the price ID doesn't match any configured plan.
  """
  def plan_for_price_id(target_price_id) when is_binary(target_price_id) do
    Enum.find([:pro, :business, :dedicated], fn plan ->
      price_id(plan) == target_price_id
    end)
  end

  def plan_for_price_id(_), do: nil

  @feature_labels %{
    sms_notifications: "SMS Notifications",
    custom_domain: "Custom Domain",
    payment_collection: "Payment Collection",
    crew_app: "Crew App"
  }

  def feature_label(feature) when is_atom(feature) do
    Map.get(@feature_labels, feature, to_string(feature))
  end
end
