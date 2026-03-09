defmodule HaulWeb.BookingLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Operations.Job

  @impl true
  def mount(_params, _session, socket) do
    operator = Application.get_env(:haul, :operator, [])
    tenant = ProvisionTenant.tenant_schema(operator[:slug] || "default")

    {:ok,
     socket
     |> assign(:page_title, "Book a Pickup")
     |> assign(:phone, operator[:phone])
     |> assign(:business_name, operator[:business_name])
     |> assign(:tenant, tenant)
     |> assign(:submitted, false)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)

    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "form"))}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    params = merge_preferred_dates(params)

    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _job} ->
        {:noreply, assign(socket, :submitted, true)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "form"))}
    end
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:submitted, false)
     |> assign_form()}
  end

  defp assign_form(socket) do
    ash_form =
      AshPhoenix.Form.for_create(Job, :create_from_online_booking,
        as: "form",
        tenant: socket.assigns.tenant
      )

    socket
    |> assign(:ash_form, ash_form)
    |> assign(:form, to_form(ash_form, as: "form"))
  end

  defp merge_preferred_dates(params) do
    dates =
      ["preferred_date_1", "preferred_date_2", "preferred_date_3"]
      |> Enum.map(&Map.get(params, &1, ""))
      |> Enum.reject(&(&1 == "" || is_nil(&1)))

    params
    |> Map.put("preferred_dates", dates)
    |> Map.drop(["preferred_date_1", "preferred_date_2", "preferred_date_3"])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-background text-foreground">
      <%= if @submitted do %>
        <section class="px-4 py-16 md:py-24 text-center max-w-2xl mx-auto">
          <div class="mb-6">
            <.icon name="hero-check-circle" class="size-16 text-foreground mx-auto" />
          </div>

          <h1 class="text-4xl md:text-5xl font-bold font-display uppercase tracking-wider mb-4">
            Thank You!
          </h1>

          <p class="text-lg text-muted-foreground mb-8">
            Your booking request has been received. We'll contact you shortly to confirm your pickup.
          </p>

          <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href={"tel:#{String.replace(@phone, ~r/[^\d+]/, "")}"}
              class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
            >
              <.icon name="hero-phone" class="size-5" />
              {@phone}
            </a>

            <button
              phx-click="reset"
              class="inline-flex items-center gap-2 border border-foreground text-foreground px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-foreground hover:text-background transition-colors"
            >
              Submit Another Request
            </button>
          </div>

          <p class="text-sm text-muted-foreground mt-8">
            {@business_name}
          </p>
        </section>
      <% else %>
        <section class="px-4 py-12 md:py-16 max-w-2xl mx-auto">
          <div class="text-center mb-10">
            <h1 class="text-4xl md:text-5xl font-bold font-display uppercase tracking-wider mb-3">
              Book a Pickup
            </h1>
            <p class="text-lg text-muted-foreground">
              Fill out the form below and we'll get back to you to confirm.
            </p>
          </div>

          <.form for={@form} phx-change="validate" phx-submit="submit" class="space-y-4">
            <.input
              field={@form[:customer_name]}
              label="Your Name"
              placeholder="Jane Doe"
              required
              class="w-full input input-lg"
              autocomplete="name"
            />

            <.input
              field={@form[:customer_phone]}
              type="tel"
              label="Phone Number"
              placeholder="(555) 123-4567"
              required
              class="w-full input input-lg"
              autocomplete="tel"
            />

            <.input
              field={@form[:customer_email]}
              type="email"
              label="Email (optional)"
              placeholder="you@example.com"
              class="w-full input input-lg"
              autocomplete="email"
            />

            <.input
              field={@form[:address]}
              label="Pickup Address"
              placeholder="123 Main St, Anytown, USA"
              required
              class="w-full input input-lg"
              autocomplete="street-address"
            />

            <.input
              field={@form[:item_description]}
              type="textarea"
              label="What do you need picked up?"
              placeholder="Old couch, two mattresses, broken dresser..."
              required
              rows="4"
              class="w-full textarea textarea-lg"
            />

            <div>
              <span class="label mb-1">Preferred Dates (optional)</span>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <input
                  type="date"
                  name="form[preferred_date_1]"
                  class="w-full input input-lg"
                  min={Date.utc_today() |> Date.to_iso8601()}
                />
                <input
                  type="date"
                  name="form[preferred_date_2]"
                  class="w-full input input-lg"
                  min={Date.utc_today() |> Date.to_iso8601()}
                />
                <input
                  type="date"
                  name="form[preferred_date_3]"
                  class="w-full input input-lg"
                  min={Date.utc_today() |> Date.to_iso8601()}
                />
              </div>
            </div>

            <div class="pt-4">
              <button
                type="submit"
                class="w-full inline-flex items-center justify-center gap-2 bg-foreground text-background px-8 py-4 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
              >
                <.icon name="hero-calendar-days" class="size-5" />
                Submit Booking Request
              </button>
            </div>
          </.form>

          <p class="text-center text-sm text-muted-foreground mt-8">
            Or call us directly:
            <a
              href={"tel:#{String.replace(@phone, ~r/[^\d+]/, "")}"}
              class="text-foreground hover:text-muted-foreground transition-colors font-semibold"
            >
              {@phone}
            </a>
          </p>
        </section>
      <% end %>
    </main>
    """
  end
end
