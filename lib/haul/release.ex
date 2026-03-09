defmodule Haul.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :haul

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Onboards a new operator tenant. For use via release eval:

      bin/haul eval "Haul.Release.onboard(%{name: \\"Joe's Hauling\\", phone: \\"555-1234\\", email: \\"joe@ex.com\\", area: \\"Seattle, WA\\"})"
  """
  def onboard(params) when is_map(params) do
    start_app()

    case Haul.Onboarding.run(params) do
      {:ok, result} ->
        log("Company: #{result.company.name} (#{result.company.slug})")
        log("Tenant: #{result.tenant}")
        log("Owner: #{result.user.email}")
        log("Site live at #{Haul.Onboarding.site_url(result.company.slug)}")
        :ok

      {:error, step, reason} ->
        log("Onboarding failed at #{step}: #{inspect(reason)}")
        :error
    end
  end

  # Console output for release eval tasks (not debug — intentional CLI output)
  defp log(msg), do: :io.put_chars(String.to_charlist(msg <> "\n"))

  defp start_app do
    load_app()
    Application.ensure_all_started(@app)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
