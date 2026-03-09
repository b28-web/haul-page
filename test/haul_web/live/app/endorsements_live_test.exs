defmodule HaulWeb.App.EndorsementsLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.Endorsement

  setup do
    on_exit(fn -> cleanup_tenants() end)
    :ok
  end

  describe "unauthenticated" do
    test "redirects to /app/login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} =
               live(conn, "/app/content/endorsements")
    end
  end

  describe "authenticated owner" do
    setup %{conn: conn} do
      ctx = create_authenticated_context(role: :owner)
      conn = log_in_user(conn, ctx)
      tenant = ProvisionTenant.tenant_schema(ctx.company.slug)
      %{conn: conn, ctx: ctx, tenant: tenant}
    end

    test "renders endorsements page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/content/endorsements")

      assert html =~ "Endorsements"
      assert html =~ "Add Endorsement"
    end

    test "renders existing endorsements", %{conn: conn, tenant: tenant} do
      create_endorsement(tenant, %{
        customer_name: "Jane Doe",
        quote_text: "Excellent service!",
        star_rating: 5,
        source: :google,
        sort_order: 1
      })

      {:ok, _view, html} = live(conn, "/app/content/endorsements")

      assert html =~ "Jane Doe"
      assert html =~ "Excellent service!"
      assert html =~ "Google"
    end

    test "adds a new endorsement", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/endorsements")

      view |> element("button", "Add Endorsement") |> render_click()

      html =
        view
        |> form("form",
          endorsement: %{
            customer_name: "John Smith",
            quote_text: "Great job hauling!",
            source: "google",
            star_rating: 5
          }
        )
        |> render_submit()

      assert html =~ "Endorsement added"
      assert html =~ "John Smith"
      assert html =~ "Great job hauling!"
    end

    test "validates form in real-time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/endorsements")

      view |> element("button", "Add Endorsement") |> render_click()

      html =
        view
        |> form("form",
          endorsement: %{customer_name: "Test User", quote_text: "Nice work"}
        )
        |> render_change()

      assert html =~ "Test User"
    end

    test "edits an existing endorsement", %{conn: conn, tenant: tenant} do
      endorsement =
        create_endorsement(tenant, %{
          customer_name: "Old Name",
          quote_text: "Old text",
          sort_order: 1
        })

      {:ok, view, _html} = live(conn, "/app/content/endorsements")

      view |> render_click("edit", %{"id" => endorsement.id})

      html =
        view
        |> form("form", endorsement: %{customer_name: "New Name"})
        |> render_submit()

      assert html =~ "Endorsement updated"
      assert html =~ "New Name"
    end

    test "deletes an endorsement with confirmation", %{conn: conn, tenant: tenant} do
      create_endorsement(tenant, %{
        customer_name: "Keep Me",
        quote_text: "Staying around",
        sort_order: 1
      })

      target =
        create_endorsement(tenant, %{
          customer_name: "Delete Me",
          quote_text: "Going away",
          sort_order: 2
        })

      {:ok, view, html} = live(conn, "/app/content/endorsements")
      assert html =~ "Delete Me"

      view |> render_click("delete", %{"id" => target.id})

      html = render(view)
      assert html =~ "cannot be undone"

      view |> render_click("confirm_delete", %{})

      endorsements = Ash.read!(Endorsement, tenant: tenant)
      assert length(endorsements) == 1
      assert hd(endorsements).customer_name == "Keep Me"
    end

    test "can delete the only endorsement", %{conn: conn, tenant: tenant} do
      endorsement =
        create_endorsement(tenant, %{
          customer_name: "Only One",
          quote_text: "Sole endorsement",
          sort_order: 1
        })

      {:ok, view, html} = live(conn, "/app/content/endorsements")
      assert html =~ "Only One"

      view |> render_click("delete", %{"id" => endorsement.id})
      view |> render_click("confirm_delete", %{})

      endorsements = Ash.read!(Endorsement, tenant: tenant)
      assert endorsements == []
    end

    test "reorders endorsements with move up", %{conn: conn, tenant: tenant} do
      create_endorsement(tenant, %{
        customer_name: "First",
        quote_text: "First endorsement",
        sort_order: 1
      })

      second =
        create_endorsement(tenant, %{
          customer_name: "Second",
          quote_text: "Second endorsement",
          sort_order: 2
        })

      {:ok, view, _html} = live(conn, "/app/content/endorsements")

      view |> render_click("move_up", %{"id" => second.id})

      {:ok, _view, html} = live(conn, "/app/content/endorsements")

      second_pos = :binary.match(html, "Second") |> elem(0)
      first_pos = :binary.match(html, "First") |> elem(0)
      assert second_pos < first_pos
    end

    test "reorders endorsements with move down", %{conn: conn, tenant: tenant} do
      first =
        create_endorsement(tenant, %{
          customer_name: "Alpha",
          quote_text: "Alpha endorsement",
          sort_order: 1
        })

      create_endorsement(tenant, %{
        customer_name: "Beta",
        quote_text: "Beta endorsement",
        sort_order: 2
      })

      {:ok, view, _html} = live(conn, "/app/content/endorsements")

      view |> render_click("move_down", %{"id" => first.id})

      {:ok, _view, html} = live(conn, "/app/content/endorsements")

      beta_pos = :binary.match(html, "Beta") |> elem(0)
      alpha_pos = :binary.match(html, "Alpha") |> elem(0)
      assert beta_pos < alpha_pos
    end

    test "cancel closes the form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/endorsements")

      view |> element("button", "Add Endorsement") |> render_click()
      html = view |> element("button", "Cancel") |> render_click()

      refute html =~ "Add Endorsement</h2>"
    end
  end

  defp create_endorsement(tenant, attrs) do
    defaults = %{
      customer_name: "Test Customer",
      quote_text: "Great service!",
      sort_order: 0
    }

    Endorsement
    |> Ash.Changeset.for_create(:add, Map.merge(defaults, attrs), tenant: tenant)
    |> Ash.create!()
  end
end
