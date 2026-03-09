defmodule HaulWeb.BillingWebhookController do
  use HaulWeb, :controller

  require Logger

  alias Haul.Accounts.Company
  alias Haul.Billing
  alias Haul.Mailer
  alias Haul.Notifications.BillingEmail

  def billing(conn, _params) do
    raw_body = conn.assigns[:raw_body] || ""
    signature = get_req_header(conn, "stripe-signature") |> List.first() || ""
    secret = Application.get_env(:haul, :stripe_billing_webhook_secret, "")

    case Haul.Payments.verify_webhook_signature(raw_body, signature, secret) do
      {:ok, event} ->
        handle_event(event)
        json(conn, %{status: "ok"})

      {:error, _reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "invalid_signature"})
    end
  end

  # -- Event handlers --

  defp handle_event(%{"type" => "checkout.session.completed"} = event) do
    object = get_in(event, ["data", "object"]) || %{}
    metadata = object["metadata"] || %{}
    customer_id = object["customer"]
    subscription_id = object["subscription"]

    company = find_company(metadata["company_id"], customer_id)

    case company do
      {:ok, company} ->
        plan = resolve_plan_from_session(object)

        attrs = %{
          subscription_plan: plan,
          stripe_customer_id: customer_id || company.stripe_customer_id,
          stripe_subscription_id: subscription_id || company.stripe_subscription_id
        }

        case update_company(company, attrs) do
          {:ok, _} ->
            Logger.info(
              "Billing webhook: checkout.session.completed for company #{company.id} — plan set to #{plan}"
            )

          {:error, reason} ->
            Logger.warning(
              "Billing webhook: failed to update company #{company.id}: #{inspect(reason)}"
            )
        end

      {:error, :not_found} ->
        Logger.warning(
          "Billing webhook: checkout.session.completed — company not found (customer: #{customer_id})"
        )
    end
  end

  defp handle_event(%{"type" => "customer.subscription.updated"} = event) do
    object = get_in(event, ["data", "object"]) || %{}
    customer_id = object["customer"]

    case find_company_by_customer(customer_id) do
      {:ok, company} ->
        plan = resolve_plan_from_subscription(object)

        if plan && plan != company.subscription_plan do
          case update_company(company, %{subscription_plan: plan}) do
            {:ok, _} ->
              Logger.info(
                "Billing webhook: subscription.updated for company #{company.id} — plan changed to #{plan}"
              )

            {:error, reason} ->
              Logger.warning(
                "Billing webhook: failed to update company #{company.id}: #{inspect(reason)}"
              )
          end
        else
          Logger.info(
            "Billing webhook: subscription.updated for company #{company.id} — no plan change"
          )
        end

      {:error, :not_found} ->
        Logger.warning(
          "Billing webhook: subscription.updated — company not found (customer: #{customer_id})"
        )
    end
  end

  defp handle_event(%{"type" => "customer.subscription.deleted"} = event) do
    object = get_in(event, ["data", "object"]) || %{}
    customer_id = object["customer"]

    case find_company_by_customer(customer_id) do
      {:ok, company} ->
        case update_company(company, %{
               subscription_plan: :starter,
               stripe_subscription_id: nil,
               dunning_started_at: nil
             }) do
          {:ok, _} ->
            Logger.info(
              "Billing webhook: subscription.deleted for company #{company.id} — downgraded to starter"
            )

          {:error, reason} ->
            Logger.warning(
              "Billing webhook: failed to downgrade company #{company.id}: #{inspect(reason)}"
            )
        end

      {:error, :not_found} ->
        Logger.warning(
          "Billing webhook: subscription.deleted — company not found (customer: #{customer_id})"
        )
    end
  end

  defp handle_event(%{"type" => "invoice.payment_failed"} = event) do
    object = get_in(event, ["data", "object"]) || %{}
    customer_id = object["customer"]
    attempt_count = object["attempt_count"] || 0

    case find_company_by_customer(customer_id) do
      {:ok, company} ->
        Logger.warning(
          "Billing webhook: invoice.payment_failed for company #{company.id} (attempt #{attempt_count})"
        )

        # Start dunning grace period after final retry (Stripe retries 3x)
        if attempt_count >= 3 && is_nil(company.dunning_started_at) do
          case update_company(company, %{dunning_started_at: DateTime.utc_now()}) do
            {:ok, _} ->
              Logger.info("Billing webhook: dunning started for company #{company.id}")

            {:error, reason} ->
              Logger.warning(
                "Billing webhook: failed to start dunning for company #{company.id}: #{inspect(reason)}"
              )
          end
        end

        # Send warning email to operator
        try do
          company |> BillingEmail.payment_failed() |> Mailer.deliver()
        rescue
          e ->
            Logger.warning("Billing webhook: failed to send payment failure email: #{inspect(e)}")
        end

      {:error, :not_found} ->
        Logger.warning(
          "Billing webhook: invoice.payment_failed — company not found (customer: #{customer_id})"
        )
    end
  end

  defp handle_event(%{"type" => "invoice.paid"} = event) do
    object = get_in(event, ["data", "object"]) || %{}
    customer_id = object["customer"]

    case find_company_by_customer(customer_id) do
      {:ok, company} ->
        if company.dunning_started_at do
          case update_company(company, %{dunning_started_at: nil}) do
            {:ok, _} ->
              Logger.info(
                "Billing webhook: invoice.paid for company #{company.id} — dunning cleared"
              )

            {:error, reason} ->
              Logger.warning(
                "Billing webhook: failed to clear dunning for company #{company.id}: #{inspect(reason)}"
              )
          end
        else
          Logger.info("Billing webhook: invoice.paid for company #{company.id}")
        end

      {:error, :not_found} ->
        Logger.warning(
          "Billing webhook: invoice.paid — company not found (customer: #{customer_id})"
        )
    end
  end

  defp handle_event(%{"type" => type}) do
    Logger.debug("Billing webhook: ignoring event type #{type}")
  end

  defp handle_event(_), do: :ok

  # -- Helpers --

  defp find_company(company_id, customer_id) when is_binary(company_id) do
    case Ash.get(Company, company_id) do
      {:ok, company} -> {:ok, company}
      {:error, _} -> find_company_by_customer(customer_id)
    end
  end

  defp find_company(_, customer_id), do: find_company_by_customer(customer_id)

  defp find_company_by_customer(nil), do: {:error, :not_found}

  defp find_company_by_customer(customer_id) do
    Company
    |> Ash.Query.for_read(:by_stripe_customer_id, %{stripe_customer_id: customer_id})
    |> Ash.read_one()
    |> case do
      {:ok, %Company{} = company} -> {:ok, company}
      _ -> {:error, :not_found}
    end
  end

  defp update_company(company, attrs) do
    company
    |> Ash.Changeset.for_update(:update_company, attrs)
    |> Ash.update()
  end

  defp resolve_plan_from_session(session) do
    metadata = session["metadata"] || %{}

    # Check metadata for explicit plan
    case metadata["plan"] do
      plan when is_binary(plan) and plan != "" ->
        String.to_existing_atom(plan)

      _ ->
        # Fall back to looking at subscription line items via mode
        resolve_plan_from_line_items(session)
    end
  rescue
    ArgumentError -> :pro
  end

  defp resolve_plan_from_line_items(session) do
    case get_in(session, ["line_items", "data"]) do
      [%{"price" => %{"id" => price_id}} | _] ->
        Billing.plan_for_price_id(price_id) || :pro

      _ ->
        # Default to pro if we can't determine the plan
        :pro
    end
  end

  defp resolve_plan_from_subscription(subscription) do
    case get_in(subscription, ["items", "data"]) do
      [%{"price" => %{"id" => price_id}} | _] ->
        Billing.plan_for_price_id(price_id)

      _ ->
        nil
    end
  end
end
