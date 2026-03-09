defmodule HaulWeb.Router do
  use HaulWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HaulWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HaulWeb.Plugs.TenantResolver
    plug HaulWeb.Plugs.EnsureChatSession
  end

  pipeline :admin_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HaulWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_with_tenant do
    plug :accepts, ["json"]
    plug HaulWeb.Plugs.TenantResolver
  end

  scope "/" do
    get "/healthz", HaulWeb.HealthController, :index
  end

  scope "/", HaulWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/scan/qr", QRController, :generate

    live_session :tenant, on_mount: [{HaulWeb.TenantHook, :resolve_tenant}] do
      live "/scan", ScanLive
      live "/book", BookingLive
      live "/pay/:job_id", PaymentLive
      live "/start", ChatLive
    end
  end

  # App admin: login (public)
  scope "/app", HaulWeb do
    pipe_through :browser

    live "/signup", App.SignupLive
    live "/login", App.LoginLive
    post "/session", AppSessionController, :create
    delete "/session", AppSessionController, :delete
  end

  # App admin: authenticated routes
  scope "/app", HaulWeb do
    pipe_through :browser

    live_session :authenticated,
      on_mount: [{HaulWeb.AuthHooks, :require_auth}],
      layout: {HaulWeb.Layouts, :admin} do
      live "/", App.DashboardLive
      live "/onboarding", App.OnboardingLive
      live "/content", App.DashboardLive
      live "/content/site", App.SiteConfigLive
      live "/content/services", App.ServicesLive
      live "/content/gallery", App.GalleryLive
      live "/content/endorsements", App.EndorsementsLive
      live "/bookings", App.DashboardLive
      live "/settings", App.DashboardLive
      live "/settings/billing", App.BillingLive
      live "/settings/domain", App.DomainSettingsLive
    end
  end

  # Superadmin: public routes (setup, login)
  scope "/admin", HaulWeb do
    pipe_through :admin_browser

    live "/setup/:token", Admin.SetupLive
    live "/login", Admin.LoginLive
    post "/session", AdminSessionController, :create
    delete "/session", AdminSessionController, :delete
    post "/exit-impersonation", AdminSessionController, :exit_impersonation
  end

  # Superadmin: authenticated routes
  scope "/admin", HaulWeb do
    pipe_through [:admin_browser, HaulWeb.Plugs.RequireAdmin]

    live_session :superadmin,
      on_mount: [{HaulWeb.AdminAuthHooks, :require_admin}],
      layout: {HaulWeb.Layouts, :superadmin} do
      live "/", Admin.DashboardLive
      live "/accounts", Admin.AccountsLive
      live "/accounts/:slug", Admin.AccountDetailLive
    end

    post "/impersonate/:slug", AdminSessionController, :impersonate
  end

  scope "/api", HaulWeb do
    pipe_through :api_with_tenant
    get "/places/autocomplete", PlacesController, :autocomplete
  end

  scope "/webhooks", HaulWeb do
    pipe_through :api
    post "/stripe", WebhookController, :stripe
    post "/stripe/billing", BillingWebhookController, :billing
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:haul, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HaulWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
      get "/sentry-test", HaulWeb.DebugController, :error
    end

    pipeline :proxy_browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {HaulWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
      plug HaulWeb.Plugs.ProxyTenantResolver
      plug HaulWeb.Plugs.EnsureChatSession
    end

    scope "/proxy/:slug", HaulWeb do
      pipe_through :proxy_browser

      get "/", PageController, :home
      get "/scan/qr", QRController, :generate

      live_session :proxy_tenant,
        on_mount: [{HaulWeb.ProxyTenantHook, :resolve_tenant}] do
        live "/scan", ScanLive
        live "/book", BookingLive
        live "/pay/:job_id", PaymentLive
        live "/start", ChatLive
      end
    end
  end
end
