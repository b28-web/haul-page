defmodule HaulWeb.ProxyHelpers do
  @moduledoc """
  Helpers for generating proxy-aware tenant paths.

  When viewing a tenant site under `/proxy/:slug/...`, internal links need
  to stay within the proxy namespace. This module provides `tenant_path/2`
  which prepends the proxy prefix when `proxy_slug` is set in assigns.
  """

  @doc """
  Returns a proxy-aware path for tenant-facing routes.

  When `proxy_slug` is set in the assigns, prepends `/proxy/:slug` to the path.
  Otherwise returns the path unchanged.

  ## Examples

      # In proxy mode:
      tenant_path(%{proxy_slug: "joes-hauling"}, "/book")
      #=> "/proxy/joes-hauling/book"

      # In normal mode:
      tenant_path(%{}, "/book")
      #=> "/book"

      # In HEEx templates:
      href={tenant_path(assigns, "/book")}
  """
  def tenant_path(assigns_or_conn, path) when is_binary(path) do
    case proxy_slug(assigns_or_conn) do
      nil -> path
      slug -> "/proxy/#{slug}#{path}"
    end
  end

  defp proxy_slug(%Plug.Conn{assigns: assigns}), do: Map.get(assigns, :proxy_slug)
  defp proxy_slug(%{proxy_slug: slug}) when is_binary(slug), do: slug
  defp proxy_slug(_), do: nil
end
