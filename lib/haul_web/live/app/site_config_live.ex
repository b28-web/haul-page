defmodule HaulWeb.App.SiteConfigLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.SiteConfig

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    tenant = ProvisionTenant.tenant_schema(company.slug)

    existing_config = load_existing_config(tenant)

    {:ok,
     socket
     |> assign(:page_title, "Site Settings")
     |> assign(:tenant, tenant)
     |> assign(:existing_config, existing_config)
     |> assign_form(existing_config)}
  end

  @impl true
  def handle_event("validate", %{"site_config" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)

    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "site_config"))}
  end

  def handle_event("save", %{"site_config" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Site settings updated")
         |> assign(:existing_config, config)
         |> assign_form(config)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "site_config"))}
    end
  end

  defp load_existing_config(tenant) do
    case Ash.read(SiteConfig, tenant: tenant) do
      {:ok, [config | _]} -> config
      _ -> nil
    end
  end

  defp assign_form(socket, nil) do
    ash_form =
      AshPhoenix.Form.for_create(SiteConfig, :create_default,
        as: "site_config",
        tenant: socket.assigns.tenant
      )

    socket
    |> assign(:ash_form, ash_form)
    |> assign(:form, to_form(ash_form, as: "site_config"))
  end

  defp assign_form(socket, %SiteConfig{} = config) do
    ash_form =
      AshPhoenix.Form.for_update(config, :edit,
        as: "site_config",
        tenant: socket.assigns.tenant
      )

    socket
    |> assign(:ash_form, ash_form)
    |> assign(:form, to_form(ash_form, as: "site_config"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl space-y-6">
      <div>
        <h1 class="font-display text-3xl uppercase tracking-wider">Site Settings</h1>
        <p class="text-muted-foreground mt-1">
          Configure your public site information. Changes take effect immediately.
        </p>
      </div>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-8">
        <%!-- Business Info --%>
        <fieldset class="space-y-4">
          <legend class="font-display text-lg uppercase tracking-wider text-muted-foreground">
            Business Info
          </legend>

          <.input
            field={@form[:business_name]}
            label="Business Name"
            placeholder="Joe's Junk Removal"
            required
          />

          <.input
            field={@form[:tagline]}
            label="Tagline"
            placeholder="Fast, affordable junk removal"
          />

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <.input
              field={@form[:phone]}
              type="tel"
              label="Phone"
              placeholder="(555) 123-4567"
              required
            />

            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="info@example.com"
            />
          </div>
        </fieldset>

        <%!-- Location --%>
        <fieldset class="space-y-4">
          <legend class="font-display text-lg uppercase tracking-wider text-muted-foreground">
            Location
          </legend>

          <.input
            field={@form[:address]}
            label="Business Address"
            placeholder="123 Main St, Anytown, USA"
          />

          <.input
            field={@form[:service_area]}
            label="Service Area"
            placeholder="Greater Portland Metro"
          />
        </fieldset>

        <%!-- Appearance --%>
        <fieldset class="space-y-4">
          <legend class="font-display text-lg uppercase tracking-wider text-muted-foreground">
            Appearance
          </legend>

          <.input
            field={@form[:primary_color]}
            label="Primary Color"
            placeholder="#0f0f0f"
          />

          <.input
            field={@form[:coupon_text]}
            label="Coupon Text"
            placeholder="10% OFF"
          />
        </fieldset>

        <%!-- SEO --%>
        <fieldset class="space-y-4">
          <legend class="font-display text-lg uppercase tracking-wider text-muted-foreground">
            SEO
          </legend>

          <.input
            field={@form[:meta_description]}
            type="textarea"
            label="Meta Description"
            placeholder="Professional junk removal services in your area..."
            rows={3}
          />
        </fieldset>

        <div class="pt-2">
          <.button type="submit" class="w-full sm:w-auto">
            Save Settings
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
