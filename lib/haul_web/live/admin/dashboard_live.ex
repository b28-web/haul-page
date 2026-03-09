defmodule HaulWeb.Admin.DashboardLive do
  use HaulWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Superadmin Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="font-display text-2xl uppercase tracking-wider text-foreground">
        Superadmin Dashboard
      </h1>
      <p class="text-muted-foreground">
        Welcome, {@current_admin.email}. This is a placeholder dashboard.
      </p>
    </div>
    """
  end
end
