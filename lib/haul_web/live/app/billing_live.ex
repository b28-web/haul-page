defmodule HaulWeb.App.BillingLive do
  use HaulWeb, :live_view

  alias Haul.Billing

  @plan_ranks %{starter: 0, pro: 1, business: 2, dedicated: 3}

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    plans = Billing.plans()

    {:ok,
     socket
     |> assign(:page_title, "Billing")
     |> assign(:plans, plans)
     |> assign(:current_plan, company.subscription_plan)
     |> assign(:loading, false)
     |> assign(:confirm_downgrade, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if params["session_id"] do
      {:noreply,
       socket
       |> put_flash(:info, "Your plan has been updated successfully.")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="billing-page" phx-hook="ExternalRedirect" class="max-w-5xl space-y-8">
      <h1 class="font-display text-3xl uppercase tracking-wider">Billing</h1>

      <div
        :if={@current_company.dunning_started_at}
        class="bg-yellow-900/30 border border-yellow-600 rounded-lg p-4 flex items-start gap-3"
      >
        <.icon name="hero-exclamation-triangle" class="size-5 text-yellow-500 mt-0.5 shrink-0" />
        <div>
          <p class="font-semibold text-yellow-400">Payment issue</p>
          <p class="text-sm text-yellow-300/80 mt-1">
            Your recent payment failed. Please update your payment method to avoid
            a plan downgrade in {days_until_downgrade(@current_company.dunning_started_at)} days.
          </p>
        </div>
      </div>

      <div class="bg-card border border-border rounded-lg p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-muted-foreground">Current Plan</p>
            <p class="text-2xl font-display uppercase tracking-wider">
              {plan_name(@current_plan)}
            </p>
            <p class="text-sm text-muted-foreground mt-1">
              {format_price(plan_price(@current_plan))}
            </p>
          </div>
          <div :if={@current_company.stripe_customer_id} class="flex gap-3">
            <button
              phx-click="manage_billing"
              disabled={@loading}
              class="px-4 py-2 text-sm border border-border rounded hover:bg-muted transition-colors"
            >
              Manage Payment Methods
            </button>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          :for={plan <- @plans}
          class={[
            "bg-card border rounded-lg p-6 flex flex-col",
            if(plan.id == @current_plan,
              do: "border-foreground ring-1 ring-foreground",
              else: "border-border"
            )
          ]}
        >
          <div class="flex-1">
            <h3 class="font-display text-xl uppercase tracking-wider">{plan.name}</h3>
            <p class="text-2xl font-bold mt-2">{format_price(plan.price_cents)}</p>

            <ul class="mt-4 space-y-2 text-sm">
              <li :if={plan.id == :starter} class="text-muted-foreground">
                Basic site with booking form
              </li>
              <li :for={feature <- plan.features} class="flex items-center gap-2">
                <.icon name="hero-check" class="size-4 text-green-500" />
                <span>{Billing.feature_label(feature)}</span>
              </li>
            </ul>
          </div>

          <div class="mt-6">
            <button
              :if={plan.id == @current_plan}
              disabled
              class="w-full px-4 py-2 text-sm bg-muted text-muted-foreground rounded cursor-not-allowed"
            >
              Current Plan
            </button>
            <button
              :if={plan.id != @current_plan && plan_rank(plan.id) > plan_rank(@current_plan)}
              phx-click="select_plan"
              phx-value-plan={plan.id}
              disabled={@loading}
              class="w-full px-4 py-2 text-sm bg-foreground text-background rounded hover:opacity-90 transition-opacity"
            >
              Upgrade to {plan.name}
            </button>
            <button
              :if={plan.id != @current_plan && plan_rank(plan.id) < plan_rank(@current_plan)}
              phx-click="select_plan"
              phx-value-plan={plan.id}
              disabled={@loading}
              class="w-full px-4 py-2 text-sm border border-border rounded hover:bg-muted transition-colors"
            >
              Downgrade to {plan.name}
            </button>
          </div>
        </div>
      </div>

      <div
        :if={@confirm_downgrade}
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
        phx-click="cancel_downgrade"
      >
        <div
          class="bg-card border border-border rounded-lg p-6 max-w-md mx-4"
          phx-click-away="cancel_downgrade"
        >
          <h2 class="font-display text-xl uppercase tracking-wider">Confirm Downgrade</h2>
          <p class="mt-3 text-sm text-muted-foreground">
            Your plan will change to
            <strong class="text-foreground">{plan_name(@confirm_downgrade)}</strong>
            at the end of your current billing period.
          </p>
          <div class="mt-6 flex gap-3 justify-end">
            <button
              phx-click="cancel_downgrade"
              class="px-4 py-2 text-sm border border-border rounded hover:bg-muted transition-colors"
            >
              Cancel
            </button>
            <button
              phx-click="confirm_downgrade"
              class="px-4 py-2 text-sm bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
            >
              Confirm Downgrade
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_plan", %{"plan" => plan_str}, socket) do
    target_plan = String.to_existing_atom(plan_str)
    current_plan = socket.assigns.current_plan

    cond do
      target_plan == current_plan ->
        {:noreply, socket}

      plan_rank(target_plan) > plan_rank(current_plan) ->
        handle_upgrade(target_plan, socket)

      true ->
        {:noreply, assign(socket, :confirm_downgrade, target_plan)}
    end
  end

  @impl true
  def handle_event("confirm_downgrade", _params, socket) do
    target_plan = socket.assigns.confirm_downgrade
    company = socket.assigns.current_company

    result =
      cond do
        target_plan == :starter && company.stripe_subscription_id ->
          Billing.cancel_subscription(company.stripe_subscription_id)

        company.stripe_subscription_id ->
          price_id = Billing.price_id(target_plan)
          Billing.update_subscription(company.stripe_subscription_id, %{price_id: price_id})

        true ->
          {:ok, :no_subscription}
      end

    case result do
      {:ok, _} ->
        {:ok, updated_company} = update_company_plan(company, target_plan)

        {:noreply,
         socket
         |> assign(:current_company, updated_company)
         |> assign(:current_plan, target_plan)
         |> assign(:confirm_downgrade, nil)
         |> put_flash(:info, "Your plan has been changed to #{plan_name(target_plan)}.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:confirm_downgrade, nil)
         |> put_flash(:error, "Failed to change plan: #{reason}")}
    end
  end

  @impl true
  def handle_event("cancel_downgrade", _params, socket) do
    {:noreply, assign(socket, :confirm_downgrade, nil)}
  end

  @impl true
  def handle_event("manage_billing", _params, socket) do
    company = socket.assigns.current_company

    case Billing.create_portal_session(company.stripe_customer_id, billing_url()) do
      {:ok, %{url: url}} ->
        {:noreply, push_event(socket, "redirect", %{url: url})}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to open billing portal: #{reason}")}
    end
  end

  # -- Private --

  defp handle_upgrade(target_plan, socket) do
    socket = assign(socket, :loading, true)

    with {:ok, socket} <- ensure_customer(socket),
         price_id when price_id not in [nil, ""] <- Billing.price_id(target_plan) do
      company = socket.assigns.current_company

      if company.stripe_subscription_id do
        case Billing.update_subscription(company.stripe_subscription_id, %{price_id: price_id}) do
          {:ok, _} ->
            {:ok, updated_company} = update_company_plan(company, target_plan)

            {:noreply,
             socket
             |> assign(:loading, false)
             |> assign(:current_company, updated_company)
             |> assign(:current_plan, target_plan)
             |> put_flash(:info, "Your plan has been upgraded to #{plan_name(target_plan)}!")}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:loading, false)
             |> put_flash(:error, "Failed to upgrade: #{reason}")}
        end
      else
        params = %{
          customer_id: company.stripe_customer_id,
          price_id: price_id,
          success_url: billing_url(),
          cancel_url: billing_url()
        }

        case Billing.create_checkout_session(params) do
          {:ok, %{url: url}} ->
            # Store the target plan so we can update on return
            {:noreply,
             socket
             |> assign(:loading, false)
             |> push_event("redirect", %{url: url})}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:loading, false)
             |> put_flash(:error, "Failed to start checkout: #{reason}")}
        end
      end
    else
      nil ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "Price not configured for this plan.")}

      "" ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "Price not configured for this plan.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "Failed to set up billing: #{reason}")}
    end
  end

  defp ensure_customer(socket) do
    company = socket.assigns.current_company

    if company.stripe_customer_id do
      {:ok, socket}
    else
      case Billing.create_customer(company) do
        {:ok, customer_id} ->
          {:ok, updated} =
            company
            |> Ash.Changeset.for_update(:update_company, %{stripe_customer_id: customer_id})
            |> Ash.update()

          {:ok, assign(socket, :current_company, updated)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp update_company_plan(company, plan) do
    company
    |> Ash.Changeset.for_update(:update_company, %{subscription_plan: plan})
    |> Ash.update()
  end

  defp plan_rank(plan), do: Map.get(@plan_ranks, plan, 0)
  defp plan_name(:starter), do: "Starter"
  defp plan_name(:pro), do: "Pro"
  defp plan_name(:business), do: "Business"
  defp plan_name(:dedicated), do: "Dedicated"
  defp plan_name(_), do: "Unknown"

  defp plan_price(plan) do
    case Enum.find(Billing.plans(), &(&1.id == plan)) do
      %{price_cents: cents} -> cents
      _ -> 0
    end
  end

  defp format_price(0), do: "Free"

  defp format_price(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    "$#{dollars}/mo"
  end

  defp billing_url do
    HaulWeb.Endpoint.url() <> "/app/settings/billing"
  end

  defp days_until_downgrade(dunning_started_at) do
    grace_days = 7
    elapsed = DateTime.diff(DateTime.utc_now(), dunning_started_at, :day)
    max(grace_days - elapsed, 0)
  end
end
