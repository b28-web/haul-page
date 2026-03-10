defmodule HaulWeb.App.EndorsementsLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.Endorsement
  alias Haul.Sortable

  import Haul.Formatting, only: [source_label: 1, star_display: 1]

  @source_options [
    {"", nil},
    {"Google", "google"},
    {"Yelp", "yelp"},
    {"Direct", "direct"},
    {"Facebook", "facebook"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    tenant = ProvisionTenant.tenant_schema(company.slug)

    {:ok,
     socket
     |> assign(:page_title, "Endorsements")
     |> assign(:tenant, tenant)
     |> assign(:source_options, @source_options)
     |> assign(:editing, nil)
     |> assign(:ash_form, nil)
     |> assign(:form, nil)
     |> assign(:delete_target, nil)
     |> load_endorsements()}
  end

  @impl true
  def handle_event("add", _params, socket) do
    ash_form =
      AshPhoenix.Form.for_create(Endorsement, :add,
        as: "endorsement",
        tenant: socket.assigns.tenant
      )

    {:noreply,
     socket
     |> assign(:editing, :new)
     |> assign(:ash_form, ash_form)
     |> assign(:form, to_form(ash_form, as: "endorsement"))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    endorsement = Enum.find(socket.assigns.endorsements, &(&1.id == id))

    ash_form =
      AshPhoenix.Form.for_update(endorsement, :edit,
        as: "endorsement",
        tenant: socket.assigns.tenant
      )

    {:noreply,
     socket
     |> assign(:editing, id)
     |> assign(:ash_form, ash_form)
     |> assign(:form, to_form(ash_form, as: "endorsement"))}
  end

  def handle_event("validate", %{"endorsement" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)

    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "endorsement"))}
  end

  def handle_event("save", %{"endorsement" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _endorsement} ->
        message =
          if socket.assigns.editing == :new,
            do: "Endorsement added",
            else: "Endorsement updated"

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:editing, nil)
         |> assign(:ash_form, nil)
         |> assign(:form, nil)
         |> load_endorsements()}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "endorsement"))}
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
    endorsement = Enum.find(socket.assigns.endorsements, &(&1.id == id))
    {:noreply, assign(socket, :delete_target, endorsement)}
  end

  def handle_event("confirm_delete", _params, socket) do
    endorsement = socket.assigns.delete_target
    tenant = socket.assigns.tenant

    # Delete version records first, then the endorsement (PaperTrail FK constraint)
    Ecto.Adapters.SQL.query!(
      Haul.Repo,
      ~s|DELETE FROM "#{tenant}".endorsements_versions WHERE version_source_id = $1|,
      [Ecto.UUID.dump!(endorsement.id)]
    )

    Ecto.Adapters.SQL.query!(
      Haul.Repo,
      ~s|DELETE FROM "#{tenant}".endorsements WHERE id = $1|,
      [Ecto.UUID.dump!(endorsement.id)]
    )

    {:noreply,
     socket
     |> put_flash(:info, "Endorsement deleted")
     |> assign(:delete_target, nil)
     |> load_endorsements()}
  end

  def handle_event("move_up", %{"id" => id}, socket) do
    reorder_endorsement(socket, id, :up)
  end

  def handle_event("move_down", %{"id" => id}, socket) do
    reorder_endorsement(socket, id, :down)
  end

  defp reorder_endorsement(socket, id, direction) do
    endorsements = socket.assigns.endorsements

    case Sortable.find_swap_index(endorsements, id, direction) do
      {:ok, idx_a, idx_b} ->
        a = Enum.at(endorsements, idx_a)
        b = Enum.at(endorsements, idx_b)

        a |> Ash.Changeset.for_update(:edit, %{sort_order: b.sort_order}) |> Ash.update!()
        b |> Ash.Changeset.for_update(:edit, %{sort_order: a.sort_order}) |> Ash.update!()

        {:noreply, load_endorsements(socket)}

      :error ->
        {:noreply, socket}
    end
  end

  defp load_endorsements(socket) do
    endorsements = Ash.read!(Endorsement, tenant: socket.assigns.tenant)
    assign(socket, :endorsements, Enum.sort_by(endorsements, & &1.sort_order))
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="font-display text-3xl uppercase tracking-wider">Endorsements</h1>
          <p class="text-muted-foreground mt-1">
            Manage customer testimonials shown on your scan page.
          </p>
        </div>
        <.button :if={@editing == nil} phx-click="add">
          <.icon name="hero-plus" class="size-4 mr-1" /> Add Endorsement
        </.button>
      </div>

      <%!-- Add/Edit form --%>
      <div :if={@form} class="border border-border rounded-lg p-6 bg-card space-y-4">
        <h2 class="font-display text-lg uppercase tracking-wider">
          {if @editing == :new, do: "Add Endorsement", else: "Edit Endorsement"}
        </h2>

        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
          <.input
            field={@form[:customer_name]}
            label="Customer Name"
            placeholder="Jane Smith"
            required
          />

          <.input
            field={@form[:quote_text]}
            type="textarea"
            label="Testimonial"
            placeholder="They did an amazing job..."
            rows={3}
            required
          />

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:source]}
              type="select"
              label="Source"
              options={@source_options}
            />

            <.input
              field={@form[:star_rating]}
              type="number"
              label="Rating (1–5)"
              min={1}
              max={5}
            />
          </div>

          <.input
            field={@form[:date]}
            type="date"
            label="Date"
          />

          <.input
            field={@form[:featured]}
            type="checkbox"
            label="Featured (highlight on landing page)"
          />

          <.input
            :if={@editing != :new}
            field={@form[:active]}
            type="checkbox"
            label="Active (visible on scan page)"
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
          Delete endorsement from <strong>{@delete_target.customer_name}</strong>? This cannot be undone.
        </p>
        <div class="flex gap-3">
          <.button phx-click="confirm_delete" class="btn-error">Delete</.button>
          <.button phx-click="cancel" class="btn-ghost">Cancel</.button>
        </div>
      </div>

      <%!-- Endorsements list --%>
      <div class="space-y-2">
        <div
          :for={{endorsement, index} <- Enum.with_index(@endorsements)}
          class={[
            "flex items-start gap-4 p-4 border border-border rounded-lg bg-card",
            !endorsement.active && "opacity-50"
          ]}
        >
          <%!-- Reorder arrows --%>
          <div class="flex flex-col gap-1 pt-1">
            <button
              :if={index > 0}
              phx-click="move_up"
              phx-value-id={endorsement.id}
              class="p-1 text-muted-foreground hover:text-foreground"
              title="Move up"
            >
              <.icon name="hero-chevron-up" class="size-4" />
            </button>
            <div :if={index == 0} class="p-1 size-6" />
            <button
              :if={index < length(@endorsements) - 1}
              phx-click="move_down"
              phx-value-id={endorsement.id}
              class="p-1 text-muted-foreground hover:text-foreground"
              title="Move down"
            >
              <.icon name="hero-chevron-down" class="size-4" />
            </button>
            <div :if={index >= length(@endorsements) - 1} class="p-1 size-6" />
          </div>

          <%!-- Content --%>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <h3 class="font-bold text-foreground">{endorsement.customer_name}</h3>
              <span
                :if={endorsement.featured}
                class="text-xs px-1.5 py-0.5 bg-yellow-500/20 text-yellow-400 rounded"
              >
                Featured
              </span>
              <span
                :if={endorsement.source}
                class="text-xs px-1.5 py-0.5 bg-muted text-muted-foreground rounded"
              >
                {source_label(endorsement.source)}
              </span>
            </div>
            <p class="text-sm text-muted-foreground mt-1 line-clamp-2">{endorsement.quote_text}</p>
            <div class="flex items-center gap-3 mt-1">
              <span :if={endorsement.star_rating} class="text-sm text-yellow-400">
                {star_display(endorsement.star_rating)}
              </span>
              <span :if={!endorsement.active} class="text-xs text-muted-foreground italic">
                Inactive
              </span>
            </div>
          </div>

          <%!-- Actions --%>
          <div :if={@editing == nil && @delete_target == nil} class="flex gap-2 shrink-0">
            <button
              phx-click="edit"
              phx-value-id={endorsement.id}
              class="p-2 text-muted-foreground hover:text-foreground"
              title="Edit"
            >
              <.icon name="hero-pencil" class="size-4" />
            </button>
            <button
              phx-click="delete"
              phx-value-id={endorsement.id}
              class="p-2 text-muted-foreground hover:text-red-400"
              title="Delete"
            >
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
        </div>

        <p :if={@endorsements == []} class="text-center text-muted-foreground py-8">
          No endorsements yet. Add your first customer testimonial to get started.
        </p>
      </div>
    </div>
    """
  end
end
