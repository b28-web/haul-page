defmodule Haul.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:request_id]}
    })

    # Supervision tree: flat :one_for_one
    # ─────────────────────────────────────
    # All children restart independently. No coupled processes require
    # grouped restart (:one_for_all/:rest_for_one). Oban manages its
    # own internal supervision. Init tasks are :transient (exit after success).
    #
    # Revisit (add intermediate supervisors) when:
    # - 15+ children, or
    # - Coupled processes needing grouped restart, or
    # - Stateful GenServers that need isolated restart budgets
    #
    # Decision: T-032-02 (docs/active/work/T-032-02/)
    children = [
      HaulWeb.Telemetry,
      Haul.Repo,
      {Oban, Application.fetch_env!(:haul, Oban)},
      {DNSCluster, query: Application.get_env(:haul, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Haul.PubSub},
      Haul.RateLimiter,
      # Init tasks — supervised, retry on failure
      Haul.Content.InitTask,
      Haul.Admin.InitTask,
      # Start to serve requests, typically the last entry
      HaulWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Haul.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HaulWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
