defmodule HaulWeb.ScanLiveTest do
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

  test "GET /scan renders the scan page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Scan to Schedule"
  end

  test "displays operator business name", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Junk &amp; Handy"
  end

  test "displays phone number as tel: link", %{conn: conn, operator: operator} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ operator[:phone]
    digits = String.replace(operator[:phone], ~r/[^\d+]/, "")
    assert html =~ "tel:#{digits}"
  end

  test "contains Book Online CTA linking to /book", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Book Online"
    assert html =~ ~s(href="/book")
  end

  test "renders gallery section with Our Work heading", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Our Work"
    assert html =~ "Before"
    assert html =~ "After"
  end

  test "renders endorsement section with customer names from content", %{
    conn: conn,
    tenant: tenant
  } do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "What Customers Say"

    endorsements = Ash.read!(Haul.Content.Endorsement, tenant: tenant)

    for endorsement <- endorsements do
      assert html =~ endorsement.customer_name
    end
  end

  test "renders star ratings for endorsements", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "hero-star-solid"
  end

  test "renders footer CTA section", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Ready to Book?"
  end

  test "renders gallery captions from content", %{conn: conn, tenant: tenant} do
    {:ok, _view, html} = live(conn, "/scan")

    items = Ash.read!(Haul.Content.GalleryItem, tenant: tenant)

    for item <- items do
      if item.caption, do: assert(html =~ item.caption)
    end
  end
end
