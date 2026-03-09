defmodule HaulWeb.SmokeTest do
  @moduledoc """
  Smoke test for all public routes. Asserts every page renders
  without crashing — no DOM assertions, just "does it return 200?"
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.Seeder

  setup do
    operator = Application.get_env(:haul, :operator)
    operator_slug = operator[:slug] || "default"

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Junk & Handy", slug: operator_slug})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)
    Seeder.seed!(tenant)

    on_exit(fn ->
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    %{operator: operator, tenant: tenant}
  end

  describe "public routes render without crashing" do
    test "GET /healthz", %{conn: conn} do
      conn = get(conn, "/healthz")
      assert response(conn, 200)
    end

    test "GET /", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200)
    end

    test "GET /scan", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/scan")
      assert html =~ "</html>"
    end

    test "GET /book", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "</html>"
    end

    test "GET /scan/qr", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr")
      assert response(conn, 200)
    end
  end
end
