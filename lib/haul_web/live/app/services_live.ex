defmodule HaulWeb.App.ServicesLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.Service

  @icon_options [
    {"Truck", "hero-truck"},
    {"Home", "hero-home-modern"},
    {"Wrench", "hero-wrench-screwdriver"},
    {"Trash", "hero-trash"},
    {"Building", "hero-building-office"},
    {"Sun", "hero-sun"},
    {"Box", "hero-cube"},
    {"Sparkles", "hero-sparkles"},
    {"Shield", "hero-shield-check"},
    {"Clock", "hero-clock"},
    {"Map Pin", "hero-map-pin"},
    {"Phone", "hero-phone"},
    {"Star", "hero-star"},
    {"Bolt", "hero-bolt"},
    {"Arrow Path", "hero-arrow-path"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    tenant = ProvisionTenant.tenant_schema(company.slug)

    {:ok,
     socket
     |> assign(:page_title, "Services")
     |> assign(:tenant, tenant)
     |> assign(:icon_options, @icon_options)
     |> assign(:editing, nil)
     |> assign(:ash_form, nil)
     |> assign(:form, nil)
     |> assign(:delete_target, nil)
     |> load_services()}
  end

  @impl true
  def handle_event("add", _params, socket) do
    ash_form =
      AshPhoenix.Form.for_create(Service, :add,
        as: "service",
        tenant: socket.assigns.tenant
      )

    {:noreply,
     socket
     |> assign(:editing, :new)
     |> assign(:ash_form, ash_form)
     |> assign(:form, to_form(ash_form, as: "service"))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    service = Enum.find(socket.assigns.services, &(&1.id == id))

    ash_form =
      AshPhoenix.Form.for_update(service, :edit,
        as: "service",
        tenant: socket.assigns.tenant
      )

    {:noreply,
     socket
     |> assign(:editing, id)
     |> assign(:ash_form, ash_form)
     |> assign(:form, to_form(ash_form, as: "service"))}
  end

  def handle_event("validate", %{"service" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)

    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "service"))}
  end

  def handle_event("save", %{"service" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _service} ->
        message =
          if socket.assigns.editing == :new,
            do: "Service added",
            else: "Service updated"

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:editing, nil)
         |> assign(:ash_form, nil)
         |> assign(:form, nil)
         |> load_services()}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "service"))}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing, nil)
     |> assign(:ash_form, nil)
     |> assign(:form, nil)
     |> assign(:delete_target, nil)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    service = Enum.find(socket.assigns.services, &(&1.id == id))
    {:noreply, assign(socket, :delete_target, service)}
  end

  def handle_event("confirm_delete", _params, socket) do
    service = socket.assigns.delete_target
    service_count = length(socket.assigns.services)

    if service_count <= 1 do
      {:noreply,
       socket
       |> put_flash(:error, "Cannot delete the last service")
       |> assign(:delete_target, nil)}
    else
      tenant = socket.assigns.tenant

      # Delete version records first, then the service (PaperTrail FK constraint)
      Ecto.Adapters.SQL.query!(
        Haul.Repo,
        ~s|DELETE FROM "#{tenant}".services_versions WHERE version_source_id = $1|,
        [Ecto.UUID.dump!(service.id)]
      )

      Ecto.Adapters.SQL.query!(
        Haul.Repo,
        ~s|DELETE FROM "#{tenant}".services WHERE id = $1|,
        [Ecto.UUID.dump!(service.id)]
      )

      {:noreply,
       socket
       |> put_flash(:info, "Service deleted")
       |> assign(:delete_target, nil)
       |> load_services()}
    end
  end

  def handle_event("move_up", %{"id" => id}, socket) do
    services = socket.assigns.services
    index = Enum.find_index(services, &(&1.id == id))

    if index && index > 0 do
      swap_sort_order(services, index, index - 1)
      {:noreply, load_services(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("move_down", %{"id" => id}, socket) do
    services = socket.assigns.services
    index = Enum.find_index(services, &(&1.id == id))

    if index && index < length(services) - 1 do
      swap_sort_order(services, index, index + 1)
      {:noreply, load_services(socket)}
    else
      {:noreply, socket}
    end
  end

  defp swap_sort_order(services, idx_a, idx_b) do
    a = Enum.at(services, idx_a)
    b = Enum.at(services, idx_b)

    a |> Ash.Changeset.for_update(:edit, %{sort_order: b.sort_order}) |> Ash.update!()
    b |> Ash.Changeset.for_update(:edit, %{sort_order: a.sort_order}) |> Ash.update!()
  end

  defp load_services(socket) do
    services = Ash.read!(Service, tenant: socket.assigns.tenant)
    assign(socket, :services, services)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="font-display text-3xl uppercase tracking-wider">Services</h1>
          <p class="text-muted-foreground mt-1">
            Manage the services shown on your landing page.
          </p>
        </div>
        <.button :if={@editing == nil} phx-click="add">
          <.icon name="hero-plus" class="size-4 mr-1" /> Add Service
        </.button>
      </div>

      <%!-- Add/Edit form --%>
      <div :if={@form} class="border border-border rounded-lg p-6 bg-card space-y-4">
        <h2 class="font-display text-lg uppercase tracking-wider">
          {if @editing == :new, do: "Add Service", else: "Edit Service"}
        </h2>

        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
          <.input field={@form[:title]} label="Title" placeholder="Junk Removal" required />

          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="We haul away anything you don't need."
            rows={3}
            required
          />

          <.input
            field={@form[:icon]}
            type="select"
            label="Icon"
            options={Enum.map(@icon_options, fn {label, value} -> {label, value} end)}
            required
          />

          <div :if={@form[:icon].value} class="flex items-center gap-2 text-muted-foreground">
            <.icon name={@form[:icon].value} class="size-6" />
            <span class="text-sm">Preview</span>
          </div>

          <.input
            :if={@editing != :new}
            field={@form[:active]}
            type="checkbox"
            label="Active (visible on landing page)"
          />

          <div class="flex gap-3 pt-2">
            <.button type="submit">Save</.button>
            <.button type="button" phx-click="cancel" class="btn-ghost">Cancel</.button>
          </div>
        </.form>
      </div>

      <%!-- Delete confirmation --%>
      <div :if={@delete_target} class="border border-error/50 rounded-lg p-6 bg-error/10 space-y-4">
        <p class="text-foreground">
          Delete <strong>{@delete_target.title}</strong>? This cannot be undone.
        </p>
        <div class="flex gap-3">
          <.button phx-click="confirm_delete" class="btn-error">Delete</.button>
          <.button phx-click="cancel" class="btn-ghost">Cancel</.button>
        </div>
      </div>

      <%!-- Services list --%>
      <div class="space-y-2">
        <div
          :for={{service, index} <- Enum.with_index(@services)}
          class={[
            "flex items-center gap-4 p-4 border border-border rounded-lg bg-card",
            !service.active && "opacity-50"
          ]}
        >
          <%!-- Reorder arrows --%>
          <div class="flex flex-col gap-1">
            <button
              :if={index > 0}
              phx-click="move_up"
              phx-value-id={service.id}
              class="p-1 text-muted-foreground hover:text-foreground"
              title="Move up"
            >
              <.icon name="hero-chevron-up" class="size-4" />
            </button>
            <div :if={index == 0} class="p-1 size-6" />
            <button
              :if={index < length(@services) - 1}
              phx-click="move_down"
              phx-value-id={service.id}
              class="p-1 text-muted-foreground hover:text-foreground"
              title="Move down"
            >
              <.icon name="hero-chevron-down" class="size-4" />
            </button>
            <div :if={index >= length(@services) - 1} class="p-1 size-6" />
          </div>

          <%!-- Icon --%>
          <.icon name={service.icon} class="size-8 shrink-0" />

          <%!-- Content --%>
          <div class="flex-1 min-w-0">
            <h3 class="font-bold text-foreground">{service.title}</h3>
            <p class="text-sm text-muted-foreground truncate">{service.description}</p>
            <span :if={!service.active} class="text-xs text-muted-foreground italic">Inactive</span>
          </div>

          <%!-- Actions --%>
          <div :if={@editing == nil && @delete_target == nil} class="flex gap-2 shrink-0">
            <button
              phx-click="edit"
              phx-value-id={service.id}
              class="p-2 text-muted-foreground hover:text-foreground"
              title="Edit"
            >
              <.icon name="hero-pencil" class="size-4" />
            </button>
            <button
              :if={length(@services) > 1}
              phx-click="delete"
              phx-value-id={service.id}
              class="p-2 text-muted-foreground hover:text-red-400"
              title="Delete"
            >
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
        </div>

        <p :if={@services == []} class="text-center text-muted-foreground py-8">
          No services yet. Add your first service to get started.
        </p>
      </div>
    </div>
    """
  end
end
