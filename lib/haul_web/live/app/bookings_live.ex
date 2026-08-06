defmodule HaulWeb.App.BookingsLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Operations.Job

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    tenant = ProvisionTenant.tenant_schema(company.slug)

    {:ok,
     socket
     |> assign(:page_title, "Bookings")
     |> assign(:tenant, tenant)
     |> assign(:selected, nil)
     |> load_jobs()}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    job = Enum.find(socket.assigns.jobs, &(&1.id == id))
    {:noreply, assign(socket, :selected, job)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :selected, nil)}
  end

  defp load_jobs(socket) do
    jobs =
      case Ash.read(Job, tenant: socket.assigns.tenant, authorize?: false) do
        {:ok, jobs} -> Enum.sort_by(jobs, & &1.inserted_at, {:desc, DateTime})
        _ -> []
      end

    assign(socket, :jobs, jobs)
  end

  defp format_date(nil), do: ""

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%b %d, %Y at %I:%M %p")
  end

  defp format_date(%Date{} = d) do
    Calendar.strftime(d, "%b %d, %Y")
  end

  defp state_badge(state) do
    case state do
      :lead -> "bg-foreground/10 text-foreground"
      _ -> "bg-muted-foreground/10 text-muted-foreground"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="font-display text-3xl uppercase tracking-wider">Bookings</h1>
        <span class="text-sm text-muted-foreground">{length(@jobs)} total</span>
      </div>

      <div :if={@jobs == []} class="border border-border p-8 text-center">
        <.icon name="hero-inbox" class="size-12 text-muted-foreground mx-auto mb-4" />
        <p class="text-lg text-muted-foreground">No bookings yet.</p>
        <p class="text-sm text-muted-foreground mt-1">
          When customers submit a booking request, it will appear here.
        </p>
      </div>

      <div :if={@jobs != []} class="space-y-3">
        <div
          :for={job <- @jobs}
          phx-click="select"
          phx-value-id={job.id}
          class={[
            "border border-border p-4 cursor-pointer hover:border-foreground transition-colors",
            @selected && @selected.id == job.id && "border-foreground bg-card"
          ]}
        >
          <div class="flex items-start justify-between gap-4">
            <div class="min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <p class="font-bold truncate">{job.customer_name}</p>
                <span class={"text-xs px-2 py-0.5 rounded-full font-medium #{state_badge(job.state)}"}>
                  {job.state}
                </span>
              </div>
              <p class="text-sm text-muted-foreground truncate">{job.item_description}</p>
            </div>
            <p class="text-xs text-muted-foreground whitespace-nowrap">{format_date(job.inserted_at)}</p>
          </div>
        </div>
      </div>

      <%!-- Detail panel --%>
      <div :if={@selected} class="border border-foreground p-6 space-y-4">
        <div class="flex items-start justify-between">
          <h2 class="font-display text-xl uppercase tracking-wider">Booking Details</h2>
          <button phx-click="close" class="text-muted-foreground hover:text-foreground">
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
          <div>
            <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Customer</p>
            <p class="font-medium">{@selected.customer_name}</p>
          </div>
          <div>
            <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Phone</p>
            <a href={"tel:#{@selected.customer_phone}"} class="font-medium underline hover:text-muted-foreground">
              {@selected.customer_phone}
            </a>
          </div>
          <div :if={@selected.customer_email}>
            <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Email</p>
            <a href={"mailto:#{@selected.customer_email}"} class="font-medium underline hover:text-muted-foreground">
              {@selected.customer_email}
            </a>
          </div>
          <div>
            <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Address</p>
            <p class="font-medium">{@selected.address}</p>
          </div>
        </div>

        <div>
          <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Description</p>
          <p class="text-sm whitespace-pre-wrap">{@selected.item_description}</p>
        </div>

        <div :if={@selected.preferred_dates != []}>
          <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Preferred Dates</p>
          <div class="flex flex-wrap gap-2">
            <span
              :for={date <- @selected.preferred_dates}
              class="text-sm bg-foreground/10 px-2 py-0.5"
            >
              {format_date(date)}
            </span>
          </div>
        </div>

        <div :if={@selected.notes}>
          <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Notes</p>
          <p class="text-sm whitespace-pre-wrap">{@selected.notes}</p>
        </div>

        <div :if={@selected.photo_urls != []}>
          <p class="text-muted-foreground text-xs uppercase tracking-wider mb-1">Photos</p>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
            <img
              :for={url <- @selected.photo_urls}
              src={url}
              class="aspect-square object-cover bg-card border border-border"
              loading="lazy"
            />
          </div>
        </div>

        <div class="pt-2 flex flex-wrap gap-3">
          <a
            href={"tel:#{@selected.customer_phone}"}
            class="inline-flex items-center gap-2 bg-foreground text-background px-6 py-2 text-sm font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
          >
            <.icon name="hero-phone" class="size-4" /> Call Customer
          </a>
          <a
            :if={@selected.customer_email}
            href={"mailto:#{@selected.customer_email}"}
            class="inline-flex items-center gap-2 border border-foreground text-foreground px-6 py-2 text-sm font-bold font-display uppercase tracking-wider hover:bg-foreground hover:text-background transition-colors"
          >
            <.icon name="hero-envelope" class="size-4" /> Email
          </a>
        </div>

        <p class="text-xs text-muted-foreground">
          Submitted {format_date(@selected.inserted_at)}
        </p>
      </div>
    </div>
    """
  end
end
