defmodule HaulWeb.PageController do
  use HaulWeb, :controller

  alias HaulWeb.ContentHelpers

  def home(conn, _params) do
    if conn.assigns[:is_platform_host] do
      marketing(conn)
    else
      operator_home(conn)
    end
  end

  defp marketing(conn) do
    conn
    |> put_layout(false)
    |> assign(:page_title, "Haul — Your hauling business online in 2 minutes")
    |> render(:marketing)
  end

  defp operator_home(conn) do
    tenant = conn.assigns[:tenant] || ContentHelpers.resolve_tenant()
    site_config = ContentHelpers.load_site_config(tenant)
    services = ContentHelpers.load_services(tenant)

    conn
    |> put_layout(false)
    |> assign(:page_title, get_field(site_config, :business_name) || "Home")
    |> assign(:business_name, get_field(site_config, :business_name))
    |> assign(:phone, get_field(site_config, :phone))
    |> assign(:email, get_field(site_config, :email))
    |> assign(:tagline, get_field(site_config, :tagline))
    |> assign(:service_area, get_field(site_config, :service_area))
    |> assign(:coupon_text, get_field(site_config, :coupon_text) || "10% OFF")
    |> assign(:services, services)
    |> assign(:url, HaulWeb.Endpoint.url())
    |> render(:home)
  end

  defp get_field(%{__struct__: _} = struct, field), do: Map.get(struct, field)
  defp get_field(map, field) when is_map(map), do: map[field]
end
