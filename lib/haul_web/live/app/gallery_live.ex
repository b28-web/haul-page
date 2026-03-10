defmodule HaulWeb.App.GalleryLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.GalleryItem
  alias Haul.{Sortable, Storage}

  import HaulWeb.Helpers, only: [friendly_upload_error: 1]

  @max_file_size 5_000_000

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    tenant = ProvisionTenant.tenant_schema(company.slug)
    items = load_items(tenant)

    {:ok,
     socket
     |> assign(:page_title, "Gallery")
     |> assign(:tenant, tenant)
     |> assign(:items, items)
     |> assign(:show_modal, false)
     |> assign(:editing_item, nil)
     |> assign(:ash_form, nil)
     |> assign(:form, nil)
     |> allow_upload(:before_image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_file_size
     )
     |> allow_upload(:after_image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_file_size
     )}
  end

  @impl true
  def handle_event("add", _params, socket) do
    ash_form =
      AshPhoenix.Form.for_create(GalleryItem, :add,
        as: "gallery_item",
        tenant: socket.assigns.tenant
      )

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:editing_item, nil)
     |> assign(:ash_form, ash_form)
     |> assign(:form, to_form(ash_form, as: "gallery_item"))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.items, &(&1.id == id))

    if item do
      ash_form =
        AshPhoenix.Form.for_update(item, :edit,
          as: "gallery_item",
          tenant: socket.assigns.tenant
        )

      {:noreply,
       socket
       |> assign(:show_modal, true)
       |> assign(:editing_item, item)
       |> assign(:ash_form, ash_form)
       |> assign(:form, to_form(ash_form, as: "gallery_item"))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate", %{"gallery_item" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "gallery_item"))}
  end

  def handle_event("save", %{"gallery_item" => params}, socket) do
    if socket.assigns.editing_item do
      save_edit(socket, params)
    else
      save_new(socket, params)
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.items, &(&1.id == id))

    if item do
      delete_storage_files(item)
      Ash.destroy!(item, tenant: socket.assigns.tenant)

      {:noreply,
       socket
       |> put_flash(:info, "Gallery item deleted")
       |> assign(:items, load_items(socket.assigns.tenant))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("move-up", %{"id" => id}, socket) do
    reorder(socket, id, :up)
  end

  def handle_event("move-down", %{"id" => id}, socket) do
    reorder(socket, id, :down)
  end

  def handle_event("toggle-active", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.items, &(&1.id == id))

    if item do
      item
      |> Ash.Changeset.for_update(:edit, %{active: !item.active}, tenant: socket.assigns.tenant)
      |> Ash.update!()

      {:noreply, assign(socket, :items, load_items(socket.assigns.tenant))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref, "name" => name}, socket) do
    upload_name = String.to_existing_atom(name)
    {:noreply, cancel_upload(socket, upload_name, ref)}
  end

  def handle_event("close-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:editing_item, nil)
     |> assign(:ash_form, nil)
     |> assign(:form, nil)}
  end

  defp save_new(socket, params) do
    tenant = socket.assigns.tenant

    before_url = upload_file(socket, :before_image, tenant, "gallery/before")
    after_url = upload_file(socket, :after_image, tenant, "gallery/after")

    if before_url && after_url do
      params =
        params
        |> Map.put("before_image_url", Storage.public_url(before_url))
        |> Map.put("after_image_url", Storage.public_url(after_url))
        |> Map.put("sort_order", Sortable.next_sort_order(socket.assigns.items))

      case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
        {:ok, _item} ->
          {:noreply,
           socket
           |> put_flash(:info, "Gallery item added")
           |> assign(:show_modal, false)
           |> assign(:editing_item, nil)
           |> assign(:items, load_items(tenant))}

        {:error, ash_form} ->
          {:noreply,
           assign(socket,
             ash_form: ash_form,
             form: to_form(ash_form, as: "gallery_item")
           )}
      end
    else
      {:noreply, put_flash(socket, :error, "Both before and after images are required")}
    end
  end

  defp save_edit(socket, params) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Gallery item updated")
         |> assign(:show_modal, false)
         |> assign(:editing_item, nil)
         |> assign(:items, load_items(socket.assigns.tenant))}

      {:error, ash_form} ->
        {:noreply,
         assign(socket,
           ash_form: ash_form,
           form: to_form(ash_form, as: "gallery_item")
         )}
    end
  end

  defp upload_file(socket, upload_name, tenant, prefix) do
    entries = socket.assigns.uploads[upload_name].entries

    if entries == [] do
      nil
    else
      [key] =
        consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
          binary = File.read!(path)
          key = Storage.upload_key(tenant, prefix, entry.client_name)

          case Storage.put_object(key, binary, entry.client_type) do
            {:ok, key} -> {:ok, key}
            {:error, _} -> {:ok, nil}
          end
        end)

      key
    end
  end

  defp delete_storage_files(item) do
    extract_key(item.before_image_url) |> maybe_delete()
    extract_key(item.after_image_url) |> maybe_delete()
  end

  defp extract_key("/uploads/" <> key), do: key
  defp extract_key("https://" <> _rest = url), do: URI.parse(url).path |> String.trim_leading("/")
  defp extract_key(_), do: nil

  defp maybe_delete(nil), do: :ok
  defp maybe_delete(key), do: Storage.delete_object(key)

  defp reorder(socket, id, direction) do
    items = socket.assigns.items

    case Sortable.find_swap_index(items, id, direction) do
      {:ok, idx, swap_idx} ->
        item = Enum.at(items, idx)
        swap = Enum.at(items, swap_idx)
        tenant = socket.assigns.tenant

        item
        |> Ash.Changeset.for_update(:reorder, %{sort_order: swap.sort_order}, tenant: tenant)
        |> Ash.update!()

        swap
        |> Ash.Changeset.for_update(:reorder, %{sort_order: item.sort_order}, tenant: tenant)
        |> Ash.update!()

        {:noreply, assign(socket, :items, load_items(tenant))}

      :error ->
        {:noreply, socket}
    end
  end

  defp load_items(tenant) do
    case Ash.read(GalleryItem, tenant: tenant) do
      {:ok, items} -> Enum.sort_by(items, & &1.sort_order)
      _ -> []
    end
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="font-display text-3xl uppercase tracking-wider">Gallery</h1>
          <p class="text-muted-foreground mt-1">
            Manage your before & after photos. Changes appear on your scan page immediately.
          </p>
        </div>
        <button
          phx-click="add"
          class="inline-flex items-center gap-2 bg-foreground text-background px-4 py-2 font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
        >
          <.icon name="hero-plus" class="size-5" /> Add Item
        </button>
      </div>

      <%= if @items == [] do %>
        <div class="border border-dashed border-border rounded-lg p-12 text-center">
          <.icon name="hero-photo" class="size-12 text-muted-foreground mx-auto mb-4" />
          <p class="text-lg text-muted-foreground">No gallery items yet</p>
          <p class="text-sm text-muted-foreground mt-1">
            Add your first before & after photo pair to get started.
          </p>
        </div>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div
            :for={{item, idx} <- Enum.with_index(@items)}
            class={[
              "border border-border bg-card p-4 space-y-3",
              !item.active && "opacity-60"
            ]}
          >
            <div class="grid grid-cols-2 gap-2">
              <div>
                <p class="text-xs text-muted-foreground mb-1 uppercase tracking-wider">Before</p>
                <img
                  src={item.before_image_url}
                  alt={item.alt_text || "Before"}
                  class="w-full aspect-square object-cover bg-muted"
                  loading="lazy"
                />
              </div>
              <div>
                <p class="text-xs text-muted-foreground mb-1 uppercase tracking-wider">After</p>
                <img
                  src={item.after_image_url}
                  alt={item.alt_text || "After"}
                  class="w-full aspect-square object-cover bg-muted"
                  loading="lazy"
                />
              </div>
            </div>

            <div>
              <p :if={item.caption} class="text-sm">{item.caption}</p>
              <div class="flex gap-2 mt-1">
                <span
                  :if={item.featured}
                  class="text-xs px-2 py-0.5 bg-foreground text-background font-display uppercase"
                >
                  Featured
                </span>
                <span
                  :if={!item.active}
                  class="text-xs px-2 py-0.5 border border-border text-muted-foreground font-display uppercase"
                >
                  Inactive
                </span>
              </div>
            </div>

            <div class="flex items-center gap-1 pt-2 border-t border-border">
              <button
                :if={idx > 0}
                phx-click="move-up"
                phx-value-id={item.id}
                class="p-1.5 text-muted-foreground hover:text-foreground"
                title="Move up"
              >
                <.icon name="hero-arrow-up" class="size-4" />
              </button>
              <button
                :if={idx < length(@items) - 1}
                phx-click="move-down"
                phx-value-id={item.id}
                class="p-1.5 text-muted-foreground hover:text-foreground"
                title="Move down"
              >
                <.icon name="hero-arrow-down" class="size-4" />
              </button>
              <div class="flex-1" />
              <button
                phx-click="toggle-active"
                phx-value-id={item.id}
                class="p-1.5 text-muted-foreground hover:text-foreground"
                title={if item.active, do: "Deactivate", else: "Activate"}
              >
                <.icon
                  name={if item.active, do: "hero-eye", else: "hero-eye-slash"}
                  class="size-4"
                />
              </button>
              <button
                phx-click="edit"
                phx-value-id={item.id}
                class="p-1.5 text-muted-foreground hover:text-foreground"
                title="Edit"
              >
                <.icon name="hero-pencil" class="size-4" />
              </button>
              <button
                phx-click="delete"
                phx-value-id={item.id}
                class="p-1.5 text-muted-foreground hover:text-error"
                title="Delete"
                data-confirm="Delete this gallery item? This cannot be undone."
              >
                <.icon name="hero-trash" class="size-4" />
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Modal --%>
      <div
        :if={@show_modal}
        class="fixed inset-0 z-50 flex items-center justify-center"
        phx-window-keydown="close-modal"
        phx-key="Escape"
      >
        <div class="fixed inset-0 bg-black/50" phx-click="close-modal" />
        <div class="relative bg-card border border-border w-full max-w-lg mx-4 p-6 space-y-6 max-h-[90vh] overflow-y-auto">
          <div class="flex items-center justify-between">
            <h2 class="font-display text-xl uppercase tracking-wider">
              {if @editing_item, do: "Edit Gallery Item", else: "Add Gallery Item"}
            </h2>
            <button
              phx-click="close-modal"
              class="p-1 text-muted-foreground hover:text-foreground"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <%!-- Upload zones (new items only) --%>
            <%= if !@editing_item do %>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <span class="label mb-1">Before Photo</span>
                  <label class="flex flex-col items-center justify-center border-2 border-dashed border-muted p-4 cursor-pointer hover:border-foreground transition-colors aspect-square">
                    <%= if @uploads.before_image.entries == [] do %>
                      <.icon name="hero-photo" class="size-8 text-muted-foreground" />
                      <span class="text-xs text-muted-foreground mt-1">Upload</span>
                    <% else %>
                      <div
                        :for={entry <- @uploads.before_image.entries}
                        class="relative w-full h-full"
                      >
                        <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-ref={entry.ref}
                          phx-value-name="before_image"
                          class="absolute top-1 right-1 bg-background/80 rounded-full p-1"
                        >
                          <.icon name="hero-x-mark" class="size-3" />
                        </button>
                      </div>
                    <% end %>
                    <.live_file_input upload={@uploads.before_image} class="hidden" />
                  </label>
                  <%= for entry <- @uploads.before_image.entries, err <- upload_errors(@uploads.before_image, entry) do %>
                    <p class="text-xs text-error mt-1">{friendly_upload_error(err)}</p>
                  <% end %>
                  <p
                    :for={err <- upload_errors(@uploads.before_image)}
                    class="text-xs text-error mt-1"
                  >
                    {friendly_upload_error(err)}
                  </p>
                </div>

                <div>
                  <span class="label mb-1">After Photo</span>
                  <label class="flex flex-col items-center justify-center border-2 border-dashed border-muted p-4 cursor-pointer hover:border-foreground transition-colors aspect-square">
                    <%= if @uploads.after_image.entries == [] do %>
                      <.icon name="hero-photo" class="size-8 text-muted-foreground" />
                      <span class="text-xs text-muted-foreground mt-1">Upload</span>
                    <% else %>
                      <div :for={entry <- @uploads.after_image.entries} class="relative w-full h-full">
                        <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-ref={entry.ref}
                          phx-value-name="after_image"
                          class="absolute top-1 right-1 bg-background/80 rounded-full p-1"
                        >
                          <.icon name="hero-x-mark" class="size-3" />
                        </button>
                      </div>
                    <% end %>
                    <.live_file_input upload={@uploads.after_image} class="hidden" />
                  </label>
                  <%= for entry <- @uploads.after_image.entries, err <- upload_errors(@uploads.after_image, entry) do %>
                    <p class="text-xs text-error mt-1">{friendly_upload_error(err)}</p>
                  <% end %>
                  <p :for={err <- upload_errors(@uploads.after_image)} class="text-xs text-error mt-1">
                    {friendly_upload_error(err)}
                  </p>
                </div>
              </div>
            <% else %>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <span class="label mb-1">Before Photo</span>
                  <img
                    src={@editing_item.before_image_url}
                    class="w-full aspect-square object-cover bg-muted"
                  />
                </div>
                <div>
                  <span class="label mb-1">After Photo</span>
                  <img
                    src={@editing_item.after_image_url}
                    class="w-full aspect-square object-cover bg-muted"
                  />
                </div>
              </div>
            <% end %>

            <.input
              field={@form[:caption]}
              label="Caption"
              placeholder="Kitchen cleanout"
            />

            <.input
              field={@form[:alt_text]}
              label="Alt Text"
              placeholder="Before and after kitchen cleanup"
            />

            <div class="flex items-center gap-2">
              <.input
                field={@form[:featured]}
                type="checkbox"
                label="Featured"
              />
            </div>

            <div class="flex gap-3 pt-2">
              <.button type="submit" class="flex-1">
                {if @editing_item, do: "Save Changes", else: "Add to Gallery"}
              </.button>
              <button
                type="button"
                phx-click="close-modal"
                class="px-4 py-2 border border-border text-muted-foreground hover:text-foreground transition-colors"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
