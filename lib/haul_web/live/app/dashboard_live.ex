defmodule HaulWeb.App.DashboardLive do
  use HaulWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company

    site_url = site_url(company)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:site_url, site_url)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl space-y-6">
      <h1 class="font-display text-3xl uppercase tracking-wider">Dashboard</h1>

      <div class="space-y-2">
        <p :if={@current_user} class="text-lg text-foreground">
          Welcome, {@current_user.name || @current_user.email}.
        </p>
        <p :if={assigns[:impersonating]} class="text-lg text-foreground">
          Viewing operator dashboard as admin.
        </p>
        <p :if={@site_url} class="text-muted-foreground">
          Your site is live at <a
            href={@site_url}
            target="_blank"
            class="underline hover:text-foreground"
          >
            {@site_url}
          </a>.
        </p>
        <p :if={@site_url} class="text-muted-foreground">
          <a
            href={"#{@site_url}?print=1"}
            target="_blank"
            class="inline-flex items-center gap-1.5 underline hover:text-foreground"
          >
            <.icon name="hero-printer" class="size-4" /> Print site as poster
          </a>
        </p>
      </div>
    </div>
    """
  end

  defp site_url(nil), do: nil

  defp site_url(company) do
    cond do
      company.domain -> "https://#{company.domain}"
      company.slug -> Haul.Onboarding.site_url(company.slug)
      true -> nil
    end
  end
end
