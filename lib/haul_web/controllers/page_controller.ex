defmodule HaulWeb.PageController do
  use HaulWeb, :controller

  def home(conn, _params) do
    operator = Application.get_env(:haul, :operator, [])

    conn
    |> put_layout(false)
    |> assign(:page_title, operator[:business_name] || "Home")
    |> assign(:business_name, operator[:business_name])
    |> assign(:phone, operator[:phone])
    |> assign(:email, operator[:email])
    |> assign(:tagline, operator[:tagline])
    |> assign(:service_area, operator[:service_area])
    |> assign(:coupon_text, operator[:coupon_text])
    |> assign(:services, operator[:services] || [])
    |> assign(:url, HaulWeb.Endpoint.url())
    |> render(:home)
  end
end
