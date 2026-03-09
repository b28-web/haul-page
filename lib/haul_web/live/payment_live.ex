defmodule HaulWeb.PaymentLive do
  use HaulWeb, :live_view

  alias Haul.Operations.Job
  alias HaulWeb.ContentHelpers

  @impl true
  def mount(%{"job_id" => job_id}, _session, socket) do
    tenant = socket.assigns.tenant
    site_config = ContentHelpers.load_site_config(tenant)
    operator = Application.get_env(:haul, :operator, [])
    amount = operator[:deposit_amount_cents] || 5000

    case Ash.get(Job, job_id, tenant: tenant) do
      {:ok, job} ->
        if job.payment_intent_id do
          {:ok,
           socket
           |> assign(:page_title, "Payment")
           |> assign(:payment_status, :already_paid)
           |> assign(:job, job)
           |> assign(:phone, get_field(site_config, :phone))
           |> assign(:business_name, get_field(site_config, :business_name))}
        else
          case Haul.Payments.create_payment_intent(%{
                 amount: amount,
                 currency: "usd",
                 metadata: %{"job_id" => job.id, "tenant" => tenant}
               }) do
            {:ok, intent} ->
              {:ok,
               socket
               |> assign(:page_title, "Payment")
               |> assign(:payment_status, :pending)
               |> assign(:error_message, nil)
               |> assign(:job, job)
               |> assign(:client_secret, intent.client_secret)
               |> assign(
                 :stripe_publishable_key,
                 Application.get_env(:haul, :stripe_publishable_key, "")
               )
               |> assign(:amount_cents, amount)
               |> assign(:phone, get_field(site_config, :phone))
               |> assign(:business_name, get_field(site_config, :business_name))
               |> assign(:tenant, tenant)}

            {:error, _reason} ->
              {:ok,
               socket
               |> assign(:page_title, "Payment")
               |> assign(:payment_status, :error)
               |> assign(:error_message, "Unable to initialize payment. Please try again.")
               |> assign(:job, job)
               |> assign(:phone, get_field(site_config, :phone))
               |> assign(:business_name, get_field(site_config, :business_name))}
          end
        end

      {:error, _} ->
        {:ok,
         socket
         |> assign(:page_title, "Payment")
         |> assign(:payment_status, :not_found)
         |> assign(:job, nil)
         |> assign(:phone, get_field(site_config, :phone))
         |> assign(:business_name, get_field(site_config, :business_name))}
    end
  end

  @impl true
  def handle_event("payment_processing", _params, socket) do
    {:noreply, assign(socket, :payment_status, :processing)}
  end

  def handle_event("payment_confirmed", %{"payment_intent_id" => intent_id}, socket) do
    case Haul.Payments.retrieve_payment_intent(intent_id) do
      {:ok, %{status: "succeeded"}} ->
        job = socket.assigns.job

        case Ash.update(job, %{payment_intent_id: intent_id},
               action: :record_payment,
               tenant: socket.assigns.tenant
             ) do
          {:ok, updated_job} ->
            {:noreply,
             socket
             |> assign(:payment_status, :succeeded)
             |> assign(:job, updated_job)}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(:payment_status, :succeeded)
             |> assign(:job, %{job | payment_intent_id: intent_id})}
        end

      {:ok, %{status: status}} ->
        {:noreply,
         socket
         |> assign(:payment_status, :failed)
         |> assign(:error_message, "Payment not completed. Status: #{status}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:payment_status, :failed)
         |> assign(:error_message, "Unable to verify payment. Please contact us.")}
    end
  end

  def handle_event("payment_failed", %{"error" => error_message}, socket) do
    {:noreply,
     socket
     |> assign(:payment_status, :failed)
     |> assign(:error_message, error_message)}
  end

  defp get_field(%{__struct__: _} = struct, field), do: Map.get(struct, field)
  defp get_field(map, field) when is_map(map), do: map[field]

  defp format_amount(cents) do
    dollars = div(cents, 100)
    remaining = rem(cents, 100)
    "$#{dollars}.#{String.pad_leading(Integer.to_string(remaining), 2, "0")}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-background text-foreground">
      <section class="px-4 py-12 md:py-16 max-w-lg mx-auto">
        <%= case @payment_status do %>
          <% :not_found -> %>
            <div class="text-center">
              <.icon
                name="hero-exclamation-triangle"
                class="size-16 text-muted-foreground mx-auto mb-6"
              />
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-4">
                Job Not Found
              </h1>
              <p class="text-lg text-muted-foreground mb-8">
                The booking you're looking for doesn't exist or the link has expired.
              </p>
              <a
                href={tenant_path(assigns, "/")}
                class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
              >
                Go Home
              </a>
            </div>
          <% :already_paid -> %>
            <div class="text-center">
              <.icon name="hero-check-circle" class="size-16 text-foreground mx-auto mb-6" />
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-4">
                Already Paid
              </h1>
              <p class="text-lg text-muted-foreground mb-8">
                Payment has already been received for this booking. Thank you!
              </p>
            </div>
          <% :error -> %>
            <div class="text-center">
              <.icon
                name="hero-exclamation-triangle"
                class="size-16 text-muted-foreground mx-auto mb-6"
              />
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-4">
                Payment Error
              </h1>
              <p class="text-lg text-muted-foreground mb-8">
                {@error_message}
              </p>
              <a
                href={tenant_path(assigns, ~p"/pay/#{@job.id}")}
                class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
              >
                Try Again
              </a>
            </div>
          <% :pending -> %>
            <div class="text-center mb-10">
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-3">
                Complete Payment
              </h1>
              <p class="text-lg text-muted-foreground">
                Booking deposit: {format_amount(@amount_cents)}
              </p>
            </div>

            <div class="bg-neutral-900 border border-neutral-700 p-6 rounded mb-6">
              <h2 class="font-display uppercase tracking-wider text-sm text-muted-foreground mb-3">
                Booking Details
              </h2>
              <dl class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <dt class="text-muted-foreground">Name</dt>
                  <dd>{@job.customer_name}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-muted-foreground">Address</dt>
                  <dd class="text-right max-w-[60%]">{@job.address}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-muted-foreground">Items</dt>
                  <dd class="text-right max-w-[60%]">{@job.item_description}</dd>
                </div>
              </dl>
            </div>

            <div
              id="stripe-payment"
              phx-hook="StripePayment"
              data-client-secret={@client_secret}
              data-publishable-key={@stripe_publishable_key}
            >
              <form id="payment-form" phx-submit="noop">
                <div data-stripe-element class="mb-6"></div>

                <button
                  type="submit"
                  class="w-full inline-flex items-center justify-center gap-2 bg-foreground text-background px-8 py-4 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
                >
                  <.icon name="hero-credit-card" class="size-5" /> Pay {format_amount(@amount_cents)}
                </button>
              </form>
            </div>

            <p class="text-center text-xs text-muted-foreground mt-6">
              Payments processed securely by Stripe. Your card details never touch our servers.
            </p>
          <% :processing -> %>
            <div class="text-center py-16">
              <div class="animate-spin size-12 border-4 border-muted-foreground border-t-foreground rounded-full mx-auto mb-6">
              </div>
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-4">
                Processing Payment
              </h1>
              <p class="text-lg text-muted-foreground">
                Please wait while we confirm your payment...
              </p>
            </div>
          <% :succeeded -> %>
            <div class="text-center">
              <.icon name="hero-check-circle" class="size-16 text-foreground mx-auto mb-6" />
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-4">
                Payment Received!
              </h1>
              <p class="text-lg text-muted-foreground mb-8">
                Your booking deposit has been received. We'll be in touch to confirm your pickup.
              </p>
              <a
                href={"tel:#{String.replace(@phone, ~r/[^\d+]/, "")}"}
                class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
              >
                <.icon name="hero-phone" class="size-5" />
                {@phone}
              </a>
              <p class="text-sm text-muted-foreground mt-8">
                {@business_name}
              </p>
            </div>
          <% :failed -> %>
            <div class="text-center">
              <.icon
                name="hero-exclamation-triangle"
                class="size-16 text-muted-foreground mx-auto mb-6"
              />
              <h1 class="text-3xl md:text-4xl font-bold font-display uppercase tracking-wider mb-4">
                Payment Failed
              </h1>
              <p class="text-lg text-muted-foreground mb-8">
                {@error_message}
              </p>
              <a
                href={tenant_path(assigns, ~p"/pay/#{@job.id}")}
                class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
              >
                Try Again
              </a>
            </div>
        <% end %>
      </section>
    </main>
    """
  end
end
