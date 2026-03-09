defmodule Haul.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HaulWeb.Telemetry,
      Haul.Repo,
      {DNSCluster, query: Application.get_env(:haul, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Haul.PubSub},
      # Start a worker by calling: Haul.Worker.start_link(arg)
      # {Haul.Worker, arg},
      # Start to serve requests, typically the last entry
      HaulWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Haul.Content.Loader.load!()

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
