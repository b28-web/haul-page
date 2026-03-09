defmodule HaulWeb.BookingLive do
  use HaulWeb, :live_view

  alias Haul.Operations.Job
  alias Haul.Storage
  alias HaulWeb.ContentHelpers

  @max_photos 5
  @max_file_size 10_000_000

  @impl true
  def mount(_params, _session, socket) do
    tenant = ContentHelpers.resolve_tenant()
    site_config = ContentHelpers.load_site_config(tenant)

    {:ok,
     socket
     |> assign(:page_title, "Book a Pickup")
     |> assign(:phone, get_field(site_config, :phone))
     |> assign(:business_name, get_field(site_config, :business_name))
     |> assign(:tenant, tenant)
     |> assign(:submitted, false)
     |> assign(:max_photos, @max_photos)
     |> allow_upload(:photos,
       accept: ~w(.jpg .jpeg .png .webp .heic),
       max_entries: @max_photos,
       max_file_size: @max_file_size
     )
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)

    {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "form"))}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    params = merge_preferred_dates(params)
    photo_urls = upload_photos(socket)
    params = Map.put(params, "photo_urls", photo_urls)

    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _job} ->
        {:noreply, assign(socket, :submitted, true)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form, form: to_form(ash_form, as: "form"))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
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

  defp upload_photos(socket) do
    tenant = socket.assigns.tenant

    consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
      binary = File.read!(path)
      key = Storage.upload_key(tenant, "jobs", entry.client_name)
      content_type = entry.client_type

      case Storage.put_object(key, binary, content_type) do
        {:ok, key} -> {:ok, key}
        {:error, _reason} -> {:ok, nil}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp get_field(%{__struct__: _} = struct, field), do: Map.get(struct, field)
  defp get_field(map, field) when is_map(map), do: map[field]

  defp friendly_error(:too_large), do: "File is too large (max 10MB)"
  defp friendly_error(:too_many_files), do: "Too many files (max #{@max_photos})"
  defp friendly_error(:not_accepted), do: "File type not supported"
  defp friendly_error(err), do: to_string(err)

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
              <span class="label mb-1">Photos of your junk (optional, up to {@max_photos})</span>
              <p class="text-sm text-muted-foreground mb-2">
                Snap a few photos so we can give you a better estimate.
              </p>

              <label class="flex items-center justify-center gap-2 border-2 border-dashed border-muted rounded-lg p-6 cursor-pointer hover:border-foreground transition-colors">
                <.icon name="hero-camera" class="size-6 text-muted-foreground" />
                <span class="text-muted-foreground">Tap to add photos</span>
                <.live_file_input upload={@uploads.photos} class="hidden" />
              </label>

              <div :if={@uploads.photos.entries != []} class="grid grid-cols-3 gap-3 mt-3">
                <div
                  :for={entry <- @uploads.photos.entries}
                  class="relative rounded-lg overflow-hidden bg-muted aspect-square"
                >
                  <.live_img_preview entry={entry} class="w-full h-full object-cover" />

                  <div
                    :if={entry.progress > 0 and entry.progress < 100}
                    class="absolute bottom-0 left-0 right-0 h-1 bg-muted"
                  >
                    <div class="h-full bg-foreground" style={"width: #{entry.progress}%"}></div>
                  </div>

                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="absolute top-1 right-1 bg-background/80 rounded-full p-1 hover:bg-background transition-colors"
                    aria-label="Remove photo"
                  >
                    <.icon name="hero-x-mark" class="size-4" />
                  </button>

                  <p
                    :for={err <- upload_errors(@uploads.photos, entry)}
                    class="text-xs text-error mt-1"
                  >
                    {friendly_error(err)}
                  </p>
                </div>
              </div>

              <p :for={err <- upload_errors(@uploads.photos)} class="text-sm text-error mt-2">
                {friendly_error(err)}
              </p>
            </div>

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
                <.icon name="hero-calendar-days" class="size-5" /> Submit Booking Request
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
