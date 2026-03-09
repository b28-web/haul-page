defmodule HaulWeb.ScanLive do
  use HaulWeb, :live_view

  alias HaulWeb.ContentHelpers

  @impl true
  def mount(_params, _session, socket) do
    tenant = socket.assigns.tenant
    site_config = ContentHelpers.load_site_config(tenant)

    {:ok,
     socket
     |> assign(:page_title, "Scan to Schedule")
     |> assign(:business_name, get_field(site_config, :business_name))
     |> assign(:phone, get_field(site_config, :phone))
     |> assign(:service_area, get_field(site_config, :service_area))
     |> assign(:gallery_items, ContentHelpers.load_gallery_items(tenant))
     |> assign(:endorsements, ContentHelpers.load_endorsements(tenant))}
  end

  defp get_field(%{__struct__: _} = struct, field), do: Map.get(struct, field)
  defp get_field(map, field) when is_map(map), do: map[field]

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-background text-foreground">
      <%!-- Hero / CTA Section --%>
      <section class="px-4 py-16 md:py-24 text-center max-w-4xl mx-auto">
        <p class="text-xs font-semibold tracking-[0.4em] uppercase text-muted-foreground mb-6">
          {@business_name}
        </p>

        <h1 class="text-6xl md:text-8xl font-bold leading-[0.82] mb-6">
          Scan to Schedule
        </h1>

        <div class="mb-8">
          <p class="text-[10px] tracking-[0.3em] uppercase text-muted-foreground mb-2">
            Call for a free estimate
          </p>
          <a
            href={"tel:#{String.replace(@phone || "", ~r/[^\d+]/, "")}"}
            class="text-5xl md:text-7xl font-bold tracking-wider font-display uppercase hover:text-muted-foreground transition-colors"
          >
            {@phone}
          </a>
        </div>

        <a
          href={tenant_path(assigns, "/book")}
          class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
        >
          <.icon name="hero-calendar-days" class="size-5" /> Book Online
        </a>
      </section>

      <%!-- Before/After Gallery --%>
      <section :if={@gallery_items != []} class="px-4 py-12 md:py-16 max-w-4xl mx-auto">
        <h2 class="text-3xl md:text-4xl font-bold text-center mb-10">
          Our Work
        </h2>

        <div class="space-y-8">
          <div :for={item <- @gallery_items} class="border border-border p-4">
            <div class="grid grid-cols-2 gap-2">
              <div>
                <p class="text-[10px] tracking-[0.3em] uppercase text-muted-foreground mb-1">
                  Before
                </p>
                <div class="aspect-[4/3] bg-card flex items-center justify-center">
                  <img
                    src={item.before_image_url}
                    alt={"Before: #{item.caption}"}
                    class="w-full h-full object-cover"
                    loading="lazy"
                    onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"
                  />
                  <div class="hidden items-center justify-center w-full h-full text-muted-foreground text-sm">
                    <.icon name="hero-photo" class="size-8" />
                  </div>
                </div>
              </div>
              <div>
                <p class="text-[10px] tracking-[0.3em] uppercase text-muted-foreground mb-1">
                  After
                </p>
                <div class="aspect-[4/3] bg-card flex items-center justify-center">
                  <img
                    src={item.after_image_url}
                    alt={"After: #{item.caption}"}
                    class="w-full h-full object-cover"
                    loading="lazy"
                    onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"
                  />
                  <div class="hidden items-center justify-center w-full h-full text-muted-foreground text-sm">
                    <.icon name="hero-photo" class="size-8" />
                  </div>
                </div>
              </div>
            </div>
            <p class="text-sm text-muted-foreground mt-3">{item.caption}</p>
          </div>
        </div>
      </section>

      <%!-- Customer Endorsements --%>
      <section :if={@endorsements != []} class="px-4 py-12 md:py-16 max-w-4xl mx-auto">
        <h2 class="text-3xl md:text-4xl font-bold text-center mb-10">
          What Customers Say
        </h2>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
          <div :for={endorsement <- @endorsements} class="border border-border p-6">
            <div :if={endorsement.star_rating} class="flex gap-0.5 mb-3">
              <.icon
                :for={_i <- 1..endorsement.star_rating}
                name="hero-star-solid"
                class="size-4 text-foreground"
              />
              <.icon
                :for={_i <- 1..(5 - endorsement.star_rating)//1}
                name="hero-star"
                class="size-4 text-muted-foreground"
              />
            </div>
            <p class="text-base leading-relaxed mb-3">
              &ldquo;{endorsement.quote_text}&rdquo;
            </p>
            <p class="text-sm text-muted-foreground">
              — {endorsement.customer_name}
            </p>
          </div>
        </div>
      </section>

      <%!-- Footer CTA --%>
      <footer class="px-4 py-16 md:py-24 text-center max-w-4xl mx-auto">
        <h2 class="text-3xl md:text-4xl font-bold mb-4">
          Ready to Book?
        </h2>

        <p class="text-lg text-muted-foreground mb-8">
          Call or book online today — free estimates, no obligation.
        </p>

        <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
          <a
            href={"tel:#{String.replace(@phone || "", ~r/[^\d+]/, "")}"}
            class="inline-flex items-center gap-2 bg-foreground text-background px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-muted-foreground transition-colors"
          >
            <.icon name="hero-phone" class="size-5" />
            {@phone}
          </a>

          <a
            href={tenant_path(assigns, "/book")}
            class="inline-flex items-center gap-2 border border-foreground text-foreground px-8 py-3 text-lg font-bold font-display uppercase tracking-wider hover:bg-foreground hover:text-background transition-colors"
          >
            <.icon name="hero-calendar-days" class="size-5" /> Book Online
          </a>
        </div>

        <p class="text-sm text-muted-foreground mt-6">
          {@business_name} · {@service_area}
        </p>
      </footer>
    </main>
    """
  end
end
