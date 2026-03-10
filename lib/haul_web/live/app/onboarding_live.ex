defmodule HaulWeb.App.OnboardingLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.{Service, SiteConfig}
  alias Haul.{Onboarding, Storage}

  import HaulWeb.Helpers, only: [friendly_upload_error: 1]

  @max_file_size 5_000_000
  @steps 1..6

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    tenant = ProvisionTenant.tenant_schema(company.slug)
    base_domain = Application.get_env(:haul, :base_domain, "haulpage.com")
    site_config = load_site_config(tenant)
    services = load_services(tenant)

    {:ok,
     socket
     |> assign(:page_title, "Set Up Your Site")
     |> assign(:step, 1)
     |> assign(:tenant, tenant)
     |> assign(:company, company)
     |> assign(:site_config, site_config)
     |> assign(:services, services)
     |> assign(:base_domain, base_domain)
     |> assign(:site_url, Onboarding.site_url(company.slug))
     |> assign_info_form(site_config)
     |> allow_upload(:logo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_file_size
     )}
  end

  @impl true
  def handle_event("next", _params, socket) do
    step = min(socket.assigns.step + 1, 6)
    {:noreply, assign(socket, :step, step)}
  end

  def handle_event("back", _params, socket) do
    step = max(socket.assigns.step - 1, 1)
    {:noreply, assign(socket, :step, step)}
  end

  def handle_event("goto", %{"step" => step}, socket) do
    step = String.to_integer(step)

    if step in @steps do
      {:noreply, assign(socket, :step, step)}
    else
      {:noreply, socket}
    end
  end

  # Step 1: Confirm Info
  def handle_event("validate_info", %{"site_config" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "site_config"))}
  end

  def handle_event("save_info", %{"site_config" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, config} ->
        {:noreply,
         socket
         |> assign(:site_config, config)
         |> assign_info_form(config)
         |> assign(:step, 2)
         |> put_flash(:info, "Site info saved")}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "site_config"))}
    end
  end

  # Step 4: Upload Logo
  def handle_event("validate_logo", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload_logo", _params, socket) do
    tenant = socket.assigns.tenant

    uploaded_urls =
      consume_uploaded_entries(socket, :logo, fn %{path: path}, entry ->
        binary = File.read!(path)
        key = Storage.upload_key(tenant, "logo", entry.client_name)
        {:ok, _key} = Storage.put_object(key, binary, entry.client_type)
        {:ok, Storage.public_url(key)}
      end)

    case uploaded_urls do
      [url | _] ->
        site_config = socket.assigns.site_config

        case site_config
             |> Ash.Changeset.for_update(:edit, %{logo_url: url}, tenant: tenant)
             |> Ash.update() do
          {:ok, updated_config} ->
            {:noreply,
             socket
             |> assign(:site_config, updated_config)
             |> assign_info_form(updated_config)
             |> put_flash(:info, "Logo uploaded")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save logo")}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "No file selected")}
    end
  end

  def handle_event("remove_logo", _params, socket) do
    tenant = socket.assigns.tenant
    site_config = socket.assigns.site_config

    case site_config
         |> Ash.Changeset.for_update(:edit, %{logo_url: nil}, tenant: tenant)
         |> Ash.update() do
      {:ok, updated_config} ->
        {:noreply,
         socket
         |> assign(:site_config, updated_config)
         |> assign_info_form(updated_config)
         |> put_flash(:info, "Logo removed")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove logo")}
    end
  end

  # Step 6: Go Live
  def handle_event("go_live", _params, socket) do
    company = socket.assigns.company

    case company
         |> Ash.Changeset.for_update(:update_company, %{onboarding_complete: true})
         |> Ash.update() do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your site is live! Welcome to your dashboard.")
         |> push_navigate(to: ~p"/app")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto space-y-8">
      <div class="text-center">
        <h1 class="font-display text-3xl uppercase tracking-wider">Set Up Your Site</h1>
        <p class="text-muted-foreground mt-1">
          Step {@step} of 6 — {step_title(@step)}
        </p>
      </div>

      <.progress_bar step={@step} />

      <div class="bg-card border border-border rounded-lg p-6">
        {render_step(assigns)}
      </div>

      <div class="flex justify-between">
        <.button
          :if={@step > 1}
          phx-click="back"
          class="bg-transparent border border-border text-foreground hover:bg-muted"
        >
          Back
        </.button>
        <div :if={@step == 1} />

        <.button :if={@step < 6 && @step != 1} phx-click="next">
          Next
        </.button>
      </div>
    </div>
    """
  end

  defp render_step(%{step: 1} = assigns) do
    ~H"""
    <h2 class="font-display text-xl uppercase tracking-wider mb-4">Confirm Your Info</h2>
    <p class="text-muted-foreground mb-6 text-sm">
      We pre-filled this from your signup. Review and update if needed.
    </p>
    <.form for={@form} phx-change="validate_info" phx-submit="save_info" class="space-y-4">
      <.input field={@form[:business_name]} label="Business Name" required />

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <.input field={@form[:phone]} type="tel" label="Phone" required />
        <.input field={@form[:email]} type="email" label="Email" />
      </div>

      <.input field={@form[:service_area]} label="Service Area" placeholder="Denver metro area" />

      <div class="pt-2">
        <.button type="submit">Save & Continue</.button>
      </div>
    </.form>
    """
  end

  defp render_step(%{step: 2} = assigns) do
    ~H"""
    <h2 class="font-display text-xl uppercase tracking-wider mb-4">Your Site Address</h2>
    <p class="text-muted-foreground mb-6 text-sm">
      Your site URL was created during signup. Here's where customers will find you:
    </p>

    <div class="bg-muted/50 border border-border rounded-lg p-6 text-center space-y-3">
      <p class="text-lg font-medium text-foreground">
        {@company.slug}.{@base_domain}
      </p>
      <p class="text-sm text-muted-foreground">
        <.link href={@site_url} target="_blank" class="underline hover:text-foreground">
          Open your site in a new tab →
        </.link>
      </p>
    </div>
    """
  end

  defp render_step(%{step: 3} = assigns) do
    ~H"""
    <h2 class="font-display text-xl uppercase tracking-wider mb-4">Your Services</h2>
    <p class="text-muted-foreground mb-6 text-sm">
      We've set up some default services for you. You can customize them anytime.
    </p>

    <div class="space-y-2 mb-6">
      <div
        :for={service <- @services}
        class="flex items-center gap-3 p-3 bg-muted/30 border border-border rounded"
      >
        <.icon :if={service.icon} name={service.icon} class="size-5 text-muted-foreground" />
        <span class="font-medium">{service.title}</span>
        <span :if={!service.active} class="text-xs text-muted-foreground">(inactive)</span>
      </div>

      <p :if={@services == []} class="text-muted-foreground text-sm italic">
        No services yet. Add some in the services editor.
      </p>
    </div>

    <.link
      navigate={~p"/app/content/services"}
      class="text-sm underline hover:text-foreground text-muted-foreground"
    >
      Edit services →
    </.link>
    """
  end

  defp render_step(%{step: 4} = assigns) do
    ~H"""
    <h2 class="font-display text-xl uppercase tracking-wider mb-4">Upload Your Logo</h2>
    <p class="text-muted-foreground mb-6 text-sm">
      Add your business logo. This is optional — you can always add it later.
    </p>

    <%= if @site_config && @site_config.logo_url do %>
      <div class="mb-6 space-y-3">
        <p class="text-sm text-muted-foreground">Current logo:</p>
        <div class="flex items-center gap-4">
          <img
            src={@site_config.logo_url}
            alt="Logo"
            class="h-16 w-16 object-contain rounded border border-border"
          />
          <.button
            phx-click="remove_logo"
            class="bg-transparent border border-border text-foreground hover:bg-red-900/20 text-sm"
          >
            Remove
          </.button>
        </div>
      </div>
    <% end %>

    <form id="logo-upload-form" phx-change="validate_logo" phx-submit="upload_logo" class="space-y-4">
      <div class="border-2 border-dashed border-border rounded-lg p-8 text-center">
        <.live_file_input upload={@uploads.logo} class="hidden" />
        <label
          for={@uploads.logo.ref}
          class="cursor-pointer space-y-2 block"
        >
          <.icon name="hero-cloud-arrow-up" class="size-10 text-muted-foreground mx-auto" />
          <p class="text-sm text-muted-foreground">
            Click to upload or drag and drop
          </p>
          <p class="text-xs text-muted-foreground">
            JPG, PNG, or WebP (max 5MB)
          </p>
        </label>
      </div>

      <%= for entry <- @uploads.logo.entries do %>
        <div class="flex items-center gap-3 p-2 bg-muted/30 rounded">
          <.live_img_preview entry={entry} class="h-12 w-12 object-contain rounded" />
          <span class="text-sm flex-1">{entry.client_name}</span>
          <.button type="submit" class="text-sm">Upload</.button>
        </div>

        <%= for err <- upload_errors(@uploads.logo, entry) do %>
          <p class="text-red-500 text-sm">{friendly_upload_error(err)}</p>
        <% end %>
      <% end %>
    </form>
    """
  end

  defp render_step(%{step: 5} = assigns) do
    ~H"""
    <h2 class="font-display text-xl uppercase tracking-wider mb-4">Preview Your Site</h2>
    <p class="text-muted-foreground mb-6 text-sm">
      Take a look at your site before going live. Everything you've set up is already visible.
    </p>

    <div class="bg-muted/50 border border-border rounded-lg p-8 text-center space-y-4">
      <.icon name="hero-globe-alt" class="size-12 text-muted-foreground mx-auto" />
      <p class="text-lg font-medium">{@site_url}</p>
      <.link
        href={@site_url}
        target="_blank"
        class="inline-flex items-center gap-2 px-4 py-2 bg-foreground text-background rounded font-medium text-sm hover:opacity-90"
      >
        Open Site in New Tab <.icon name="hero-arrow-top-right-on-square" class="size-4" />
      </.link>
    </div>
    """
  end

  defp render_step(%{step: 6} = assigns) do
    ~H"""
    <h2 class="font-display text-xl uppercase tracking-wider mb-4">Go Live!</h2>
    <p class="text-muted-foreground mb-6 text-sm">
      Everything looks good? Hit the button below to mark your site as ready.
      You can always come back to make changes later.
    </p>

    <div class="text-center space-y-6 py-4">
      <div class="space-y-2">
        <p class="text-sm text-muted-foreground">Your site:</p>
        <p class="text-lg font-medium">{@site_url}</p>
      </div>

      <.button phx-click="go_live" class="text-lg px-8 py-3">
        Launch My Site
      </.button>
    </div>
    """
  end

  attr :step, :integer, required: true

  defp progress_bar(assigns) do
    ~H"""
    <div class="flex items-center justify-between px-4">
      <%= for i <- 1..6 do %>
        <button
          phx-click="goto"
          phx-value-step={i}
          class={[
            "w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium transition-colors",
            if(i == @step, do: "bg-foreground text-background", else: ""),
            if(i < @step, do: "bg-foreground/60 text-background", else: ""),
            if(i > @step, do: "bg-muted text-muted-foreground border border-border", else: "")
          ]}
        >
          {i}
        </button>
        <div
          :if={i < 6}
          class={[
            "flex-1 h-0.5 mx-1",
            if(i < @step, do: "bg-foreground/60", else: "bg-border")
          ]}
        />
      <% end %>
    </div>
    """
  end

  defp step_title(1), do: "Confirm Info"
  defp step_title(2), do: "Your Site"
  defp step_title(3), do: "Services"
  defp step_title(4), do: "Upload Logo"
  defp step_title(5), do: "Preview"
  defp step_title(6), do: "Go Live"


  defp load_site_config(tenant) do
    case Ash.read(SiteConfig, tenant: tenant) do
      {:ok, [config | _]} -> config
      _ -> nil
    end
  end

  defp load_services(tenant) do
    case Ash.read(Service, tenant: tenant) do
      {:ok, services} -> Enum.sort_by(services, & &1.sort_order)
      _ -> []
    end
  end

  defp assign_info_form(socket, nil) do
    ash_form =
      AshPhoenix.Form.for_create(SiteConfig, :create_default,
        as: "site_config",
        tenant: socket.assigns.tenant
      )

    socket
    |> assign(:ash_form, ash_form)
    |> assign(:form, to_form(ash_form, as: "site_config"))
  end

  defp assign_info_form(socket, %SiteConfig{} = config) do
    ash_form =
      AshPhoenix.Form.for_update(config, :edit,
        as: "site_config",
        tenant: socket.assigns.tenant
      )

    socket
    |> assign(:ash_form, ash_form)
    |> assign(:form, to_form(ash_form, as: "site_config"))
  end
end
