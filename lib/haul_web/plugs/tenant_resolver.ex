defmodule HaulWeb.Plugs.TenantResolver do
  @moduledoc """
  Resolves tenant context from the HTTP Host header.

  Resolution order:
  1. Custom domain — look up Company by `domain` field
  2. Subdomain — extract prefix from Host, look up Company by `slug`
  3. Fallback — use operator config slug as demo tenant

  Sets `conn.assigns.current_tenant` (Company struct or nil) and
  `conn.assigns.tenant` (Postgres schema string for Ash operations).
  """
  import Plug.Conn
  require Ash.Query

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    host = conn.host
    base_domain = Application.get_env(:haul, :base_domain, "localhost")
    is_platform_host = platform_host?(host, base_domain)

    case resolve_company(host) do
      {:ok, %Company{} = company} ->
        tenant = ProvisionTenant.tenant_schema(company.slug)

        conn
        |> assign(:current_tenant, company)
        |> assign(:tenant, tenant)
        |> assign(:is_platform_host, false)
        |> maybe_put_session("tenant_slug", company.slug)
        |> store_remote_ip()

      :fallback ->
        slug = fallback_slug()
        tenant = ProvisionTenant.tenant_schema(slug)

        conn
        |> assign(:current_tenant, nil)
        |> assign(:tenant, tenant)
        |> assign(:is_platform_host, is_platform_host)
        |> maybe_put_session("tenant_slug", slug)
        |> store_remote_ip()
    end
  end

  defp resolve_company(host) do
    with :not_found <- resolve_by_domain(host),
         :not_found <- resolve_by_subdomain(host) do
      :fallback
    end
  end

  defp resolve_by_domain(host) do
    Company
    |> Ash.Query.filter(domain == ^host)
    |> Ash.read_one()
    |> case do
      {:ok, %Company{} = company} -> {:ok, company}
      _ -> :not_found
    end
  end

  defp resolve_by_subdomain(host) do
    base_domain = Application.get_env(:haul, :base_domain, "localhost")

    case extract_subdomain(host, base_domain) do
      nil ->
        :not_found

      subdomain ->
        Company
        |> Ash.Query.filter(slug == ^subdomain)
        |> Ash.read_one()
        |> case do
          {:ok, %Company{} = company} -> {:ok, company}
          _ -> :not_found
        end
    end
  end

  @doc """
  Extracts the subdomain prefix from a host given a base domain.

  Returns nil if the host is the base domain itself or doesn't end with it.

  ## Examples

      iex> HaulWeb.Plugs.TenantResolver.extract_subdomain("joes.haulpage.com", "haulpage.com")
      "joes"

      iex> HaulWeb.Plugs.TenantResolver.extract_subdomain("haulpage.com", "haulpage.com")
      nil
  """
  def extract_subdomain(host, base_domain) do
    suffix = ".#{base_domain}"

    if String.ends_with?(host, suffix) do
      prefix = String.replace_suffix(host, suffix, "")
      if prefix != "", do: prefix, else: nil
    else
      nil
    end
  end

  @doc """
  Returns true if the host is the bare platform domain (no subdomain).

  ## Examples

      iex> HaulWeb.Plugs.TenantResolver.platform_host?("haulpage.com", "haulpage.com")
      true

      iex> HaulWeb.Plugs.TenantResolver.platform_host?("joes.haulpage.com", "haulpage.com")
      false

      iex> HaulWeb.Plugs.TenantResolver.platform_host?("localhost", "localhost")
      true
  """
  def platform_host?(host, base_domain), do: host == base_domain

  defp maybe_put_session(%{private: %{plug_session: _}} = conn, key, value) do
    put_session(conn, key, value)
  end

  defp maybe_put_session(conn, _key, _value), do: conn

  defp store_remote_ip(%{private: %{plug_session: _}} = conn) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    put_session(conn, "remote_ip", ip)
  end

  defp store_remote_ip(conn), do: conn

  defp fallback_slug do
    operator = Application.get_env(:haul, :operator, [])
    operator[:slug] || "default"
  end
end
