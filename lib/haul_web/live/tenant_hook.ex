defmodule HaulWeb.TenantHook do
  @moduledoc """
  LiveView on_mount hook that resolves tenant context from the session.

  Reads the `tenant_slug` stored by TenantResolver plug, loads the Company
  from the database, and sets `socket.assigns.tenant` and
  `socket.assigns.current_tenant`. Re-verifies on every mount including
  WebSocket reconnects.
  """
  import Phoenix.Component

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company

  require Ash.Query

  def on_mount(:resolve_tenant, _params, session, socket) do
    case session["tenant_slug"] do
      slug when is_binary(slug) and slug != "" ->
        resolve_and_assign(socket, slug)

      _ ->
        {:cont, assign_fallback(socket)}
    end
  end

  defp resolve_and_assign(socket, slug) do
    case load_company(slug) do
      {:ok, %Company{} = company} ->
        tenant = ProvisionTenant.tenant_schema(company.slug)

        {:cont,
         socket
         |> assign(:current_tenant, company)
         |> assign(:tenant, tenant)}

      _ ->
        {:cont, assign_fallback(socket)}
    end
  end

  defp load_company(slug) do
    Company
    |> Ash.Query.filter(slug == ^slug)
    |> Ash.read_one()
  end

  defp assign_fallback(socket) do
    operator = Application.get_env(:haul, :operator, [])
    slug = operator[:slug] || "default"
    tenant = ProvisionTenant.tenant_schema(slug)

    socket
    |> assign(:current_tenant, nil)
    |> assign(:tenant, tenant)
  end
end
