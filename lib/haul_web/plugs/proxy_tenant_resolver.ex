defmodule HaulWeb.Plugs.ProxyTenantResolver do
  @moduledoc """
  Resolves tenant context from the URL path parameter `:slug`.

  Used in the `/proxy/:slug` dev route scope to preview any tenant's site
  without subdomain DNS. Unlike TenantResolver, returns 404 for unknown
  slugs instead of falling back to a default tenant.

  Sets `conn.assigns.current_tenant`, `conn.assigns.tenant`,
  `conn.assigns.proxy_slug`, and `conn.assigns.is_platform_host`.
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
    slug = conn.path_params["slug"]

    case resolve_by_slug(slug) do
      {:ok, %Company{} = company} ->
        tenant = ProvisionTenant.tenant_schema(company.slug)

        conn
        |> assign(:current_tenant, company)
        |> assign(:tenant, tenant)
        |> assign(:proxy_slug, company.slug)
        |> assign(:is_platform_host, false)
        |> put_session("tenant_slug", company.slug)
        |> put_session("proxy_slug", company.slug)

      :not_found ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "Tenant not found")
        |> halt()
    end
  end

  defp resolve_by_slug(nil), do: :not_found

  defp resolve_by_slug(slug) do
    Company
    |> Ash.Query.filter(slug == ^slug)
    |> Ash.read_one()
    |> case do
      {:ok, %Company{} = company} -> {:ok, company}
      _ -> :not_found
    end
  end
end
