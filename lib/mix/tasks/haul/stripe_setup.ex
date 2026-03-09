defmodule Mix.Tasks.Haul.StripeSetup do
  @moduledoc """
  Creates Stripe Products and Prices for subscription tiers.

  This is an idempotent one-time setup task. Run it against your Stripe
  account (test or live) to create the subscription products.

      mix haul.stripe_setup

  The task prints the created Price IDs. Set these as environment variables:

      STRIPE_PRICE_PRO=price_...
      STRIPE_PRICE_BUSINESS=price_...
      STRIPE_PRICE_DEDICATED=price_...
  """
  use Mix.Task

  @shortdoc "Create Stripe Products and Prices for subscription tiers"

  @products [
    %{name: "Pro", amount: 2900, metadata_key: "haul_plan_pro"},
    %{name: "Business", amount: 7900, metadata_key: "haul_plan_business"},
    %{name: "Dedicated", amount: 14_900, metadata_key: "haul_plan_dedicated"}
  ]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    api_key = Application.get_env(:stripity_stripe, :api_key)

    if api_key in [nil, ""] do
      Mix.shell().error("No Stripe API key configured. Set STRIPE_SECRET_KEY.")
      exit({:shutdown, 1})
    end

    Mix.shell().info("Creating Stripe subscription products...\n")

    for product_def <- @products do
      create_product_and_price(product_def)
    end

    Mix.shell().info("\nDone. Set the price IDs above as environment variables.")
  end

  defp create_product_and_price(%{name: name, amount: amount, metadata_key: key}) do
    case Stripe.Product.create(%{
           name: "Haul Page — #{name}",
           metadata: %{haul_plan: key}
         }) do
      {:ok, product} ->
        case Stripe.Price.create(%{
               product: product.id,
               unit_amount: amount,
               currency: "usd",
               recurring: %{interval: "month"}
             }) do
          {:ok, price} ->
            env_var =
              key
              |> String.replace("haul_plan_", "STRIPE_PRICE_")
              |> String.upcase()

            Mix.shell().info("#{name}: #{env_var}=#{price.id}")

          {:error, error} ->
            Mix.shell().error("Failed to create price for #{name}: #{inspect(error)}")
        end

      {:error, error} ->
        Mix.shell().error("Failed to create product #{name}: #{inspect(error)}")
    end
  end
end
