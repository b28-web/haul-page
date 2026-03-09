defmodule Haul.Admin.Bootstrap do
  @moduledoc """
  Bootstraps the superadmin account from the ADMIN_EMAIL environment variable.

  On startup, if ADMIN_EMAIL is set and no AdminUser exists with that email,
  creates an AdminUser with a one-time setup token and logs the setup URL.
  """

  alias Haul.Admin.AdminUser

  require Ash.Query
  require Logger

  @doc """
  Checks for ADMIN_EMAIL env var and creates an AdminUser if needed.
  Returns :ok if a new admin was created, :noop otherwise.
  """
  def ensure_admin! do
    case System.get_env("ADMIN_EMAIL") do
      nil -> :noop
      "" -> :noop
      email -> maybe_create_admin(email)
    end
  end

  defp maybe_create_admin(email) do
    case AdminUser |> Ash.Query.filter(email == ^email) |> Ash.read_one(authorize?: false) do
      {:ok, nil} -> create_admin(email)
      {:ok, _existing} -> :noop
      {:error, _} -> :noop
    end
  end

  defp create_admin(email) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

    case AdminUser
         |> Ash.Changeset.for_create(
           :create_bootstrap,
           %{email: email, setup_token_hash_value: token_hash},
           authorize?: false
         )
         |> Ash.create() do
      {:ok, _admin} ->
        host = admin_host()
        Logger.info("[admin] Setup link: #{host}/admin/setup/#{raw_token}")
        :ok

      {:error, error} ->
        Logger.error("[admin] Failed to create admin user: #{inspect(error)}")
        :noop
    end
  end

  defp admin_host do
    endpoint_config = Application.get_env(:haul, HaulWeb.Endpoint, [])

    case Keyword.get(endpoint_config, :url, []) do
      url_config ->
        scheme = Keyword.get(url_config, :scheme, "http")
        host = Keyword.get(url_config, :host, "localhost")
        port = Keyword.get(url_config, :port, 4000)

        case {scheme, port} do
          {"https", 443} -> "https://#{host}"
          {"http", 80} -> "http://#{host}"
          {scheme, port} -> "#{scheme}://#{host}:#{port}"
        end
    end
  end
end
