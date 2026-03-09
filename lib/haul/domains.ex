defmodule Haul.Domains.CertAdapter do
  @moduledoc false
  @callback add_cert(domain :: String.t()) :: {:ok, map()} | {:error, term()}
  @callback check_cert(domain :: String.t()) :: {:ok, :ready | :pending} | {:error, term()}
  @callback remove_cert(domain :: String.t()) :: :ok | {:error, term()}
end

defmodule Haul.Domains do
  @moduledoc """
  Domain validation, DNS verification, and TLS certificate provisioning for custom domains.
  """

  @domain_regex ~r/^[a-z0-9]([a-z0-9\-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]*[a-z0-9])?)+$/

  @doc """
  Normalizes a domain input by stripping protocol, path, and downcasing.

      iex> Haul.Domains.normalize_domain("HTTPS://Www.Example.Com/path")
      "www.example.com"

      iex> Haul.Domains.normalize_domain("example.com")
      "example.com"
  """
  def normalize_domain(input) when is_binary(input) do
    input
    |> String.trim()
    |> String.replace(~r{^https?://}i, "")
    |> String.split("/", parts: 2)
    |> List.first()
    |> String.downcase()
  end

  def normalize_domain(_), do: ""

  @doc """
  Validates that a string is a valid domain name with at least one dot.

      iex> Haul.Domains.valid_domain?("www.example.com")
      true

      iex> Haul.Domains.valid_domain?("localhost")
      false
  """
  def valid_domain?(domain) when is_binary(domain) do
    Regex.match?(@domain_regex, domain) and String.contains?(domain, ".")
  end

  def valid_domain?(_), do: false

  @doc """
  Verifies that a domain's CNAME record points to the base domain.

  Returns `:ok` if verified, `{:error, reason}` otherwise.
  """
  def verify_dns(domain, base_domain) do
    charlist_domain = String.to_charlist(domain)

    case :inet_res.lookup(charlist_domain, :in, :cname, timeout: 5_000) do
      [] ->
        # No CNAME found — check if there's an A record as fallback
        {:error, :no_cname}

      cname_records ->
        target = String.to_charlist(base_domain <> ".")

        if Enum.any?(cname_records, fn cname ->
             String.downcase(to_string(cname)) == String.downcase(to_string(target))
           end) do
          :ok
        else
          {:error, :wrong_cname}
        end
    end
  rescue
    _ -> {:error, :dns_error}
  end

  # -- Certificate adapter dispatch --

  def add_cert(domain), do: cert_adapter().add_cert(domain)
  def check_cert(domain), do: cert_adapter().check_cert(domain)
  def remove_cert(domain), do: cert_adapter().remove_cert(domain)

  defp cert_adapter do
    Application.get_env(:haul, :cert_adapter, Haul.Domains.Sandbox)
  end
end
