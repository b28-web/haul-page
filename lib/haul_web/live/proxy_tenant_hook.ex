defmodule HaulWeb.ProxyTenantHook do
  @moduledoc """
  LiveView on_mount hook for proxy tenant resolution.

  Reads `tenant_slug` and `proxy_slug` from the session (set by
  ProxyTenantResolver), loads the Company, and sets socket assigns.
  Unlike TenantHook, also sets `proxy_slug` on the socket and returns
  an error instead of falling back when the tenant is missing.
  """
  import Phoenix.Component

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company

  require Ash.Query

  def on_mount(:resolve_tenant, _params, session, socket) do
    slug = session["tenant_slug"]
    proxy_slug = session["proxy_slug"]

    case load_company(slug) do
      {:ok, %Company{} = company} ->
        tenant = ProvisionTenant.tenant_schema(company.slug)

        {:cont,
         socket
         |> assign(:current_tenant, company)
         |> assign(:tenant, tenant)
         |> assign(:proxy_slug, proxy_slug)}

      _ ->
        {:halt,
         socket
         |> Phoenix.LiveView.redirect(to: "/")}
    end
  end

  defp load_company(nil), do: :error

  defp load_company(slug) do
    Company
    |> Ash.Query.filter(slug == ^slug)
    |> Ash.read_one()
  end
end
