defmodule HaulWeb.ProxyHelpersTest do
  use ExUnit.Case, async: true

  import HaulWeb.ProxyHelpers

  describe "tenant_path/2" do
    test "prepends proxy prefix when proxy_slug is set" do
      assigns = %{proxy_slug: "joes-hauling"}
      assert tenant_path(assigns, "/book") == "/proxy/joes-hauling/book"
    end

    test "returns path unchanged when proxy_slug is absent" do
      assigns = %{}
      assert tenant_path(assigns, "/book") == "/book"
    end

    test "returns path unchanged when proxy_slug is nil" do
      assigns = %{proxy_slug: nil}
      assert tenant_path(assigns, "/book") == "/book"
    end

    test "handles root path" do
      assigns = %{proxy_slug: "joe"}
      assert tenant_path(assigns, "/") == "/proxy/joe/"
    end

    test "handles nested paths" do
      assigns = %{proxy_slug: "joe"}
      assert tenant_path(assigns, "/pay/abc-123") == "/proxy/joe/pay/abc-123"
    end

    test "works with Plug.Conn struct" do
      conn = %Plug.Conn{assigns: %{proxy_slug: "joe"}}
      assert tenant_path(conn, "/book") == "/proxy/joe/book"
    end

    test "works with Plug.Conn without proxy_slug" do
      conn = %Plug.Conn{assigns: %{}}
      assert tenant_path(conn, "/book") == "/book"
    end
  end
end
