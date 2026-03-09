defmodule Haul.Domains.FlyApi do
  @moduledoc false
  @behaviour Haul.Domains.CertAdapter

  require Logger

  @base_url "https://api.machines.dev/v1"

  @impl true
  def add_cert(domain) do
    case Req.post(url("/certificates"), json: %{hostname: domain}, headers: auth_headers()) do
      {:ok, %Req.Response{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning(
          "Fly cert add failed for #{domain}: status=#{status} body=#{inspect(body)}"
        )

        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.warning("Fly cert add request failed for #{domain}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def check_cert(domain) do
    case Req.get(url("/certificates/#{domain}"), headers: auth_headers()) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case get_in(body, ["data", "attributes", "check"]) || body["check"] do
          true -> {:ok, :ready}
          _ -> {:ok, :pending}
        end

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning("Fly cert check failed for #{domain}: status=#{status}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.warning("Fly cert check request failed for #{domain}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def remove_cert(domain) do
    case Req.delete(url("/certificates/#{domain}"), headers: auth_headers()) do
      {:ok, %Req.Response{status: status}} when status in [200, 204, 404] ->
        :ok

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning("Fly cert remove failed for #{domain}: status=#{status}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.warning("Fly cert remove request failed for #{domain}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp url(path) do
    app_name = Application.fetch_env!(:haul, :fly_app_name)
    "#{@base_url}/apps/#{app_name}#{path}"
  end

  defp auth_headers do
    token = Application.fetch_env!(:haul, :fly_api_token)
    [{"authorization", "Bearer #{token}"}]
  end
end
