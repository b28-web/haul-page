defmodule HaulWeb.ProvisionQATest do
  @moduledoc """
  Browser QA for the full AI provision pipeline (T-020-05).
  End-to-end: chat → extraction → provisioning → preview → edit → go live → tenant site.
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.AI.Chat.Sandbox, as: ChatSandbox
  alias Haul.AI.Conversation
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.AI.Provisioner
  alias Haul.Content.{Service, SiteConfig}

  @profile %OperatorProfile{
    business_name: "QA Pipeline Co",
    owner_name: "Pipeline Owner",
    phone: "555-7777",
    email: "qa@pipeline.example.com",
    service_area: "QA Metro",
    tagline: "Pipeline tested!",
    years_in_business: 5,
    services: [
      %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal},
      %ServiceOffering{name: "Yard Waste", description: nil, category: :yard_waste}
    ],
    differentiators: ["Fast turnaround", "Eco-friendly"]
  }

  setup do
    clear_rate_limits()
    ChatSandbox.clear_response()
    ChatSandbox.clear_error()

    on_exit(fn ->
      {:ok, res} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- res.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    :ok
  end

  defp provision_and_enter_edit_mode(conn) do
    {:ok, view, _html} = live(conn, "/start")

    {:ok, conv} =
      Conversation
      |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
      |> Ash.create()

    {:ok, result} = Provisioner.from_profile(@profile, conv.id)

    # Set profile (normally happens during extraction before provisioning)
    send(view.pid, {:extraction_result, {:ok, @profile}})
    Process.sleep(50)

    # Simulate provisioning_complete PubSub message
    send(
      view.pid,
      {:provisioning_complete,
       %{
         site_url: result.site_url,
         company_name: result.company.name,
         tenant: result.tenant,
         company: result.company,
         duration_ms: 100
       }}
    )

    Process.sleep(50)

    {view, result}
  end

  describe "full pipeline: chat → provision → preview" do
    test "chat UI renders and accepts messages before provisioning", %{conn: conn} do
      ChatSandbox.set_response("Welcome! Tell me about your business.")
      {:ok, view, html} = live(conn, "/start")

      assert html =~ "Get Started"
      assert html =~ "Type a message..."

      view
      |> form("form", %{text: "I run QA Pipeline Co in QA Metro"})
      |> render_submit()

      Process.sleep(500)
      html = render(view)

      assert html =~ "QA Pipeline Co"
      assert html =~ "Welcome! Tell me about your business."
    end

    test "provisioning enters edit mode with preview panel", %{conn: conn} do
      {view, result} = provision_and_enter_edit_mode(conn)
      html = render(view)

      # Edit mode activated
      assert html =~ "Preview &amp; Edit"
      assert html =~ "Site Preview"
      assert html =~ "0 of 10 edits used"

      # Preview URL present
      assert html =~ result.site_url
      assert html =~ "Open in new tab"
      assert html =~ "Looks good"
    end

    test "shows building message during provisioning", %{conn: conn} do
      ChatSandbox.set_response("Got it!")
      {:ok, view, _html} = live(conn, "/start")

      # Trigger extraction to make profile complete
      send(view.pid, {:extraction_result, {:ok, @profile}})
      Process.sleep(50)

      # Click build my site
      html = render_click(view, "provision_site")
      assert html =~ "Building your site"
    end

    test "provisioning_complete message shows edit instructions", %{conn: conn} do
      {view, _result} = provision_and_enter_edit_mode(conn)
      html = render(view)

      assert html =~ "take a look"
      assert html =~ "Request changes"
    end
  end

  describe "edit in preview mode" do
    test "tagline edit updates SiteConfig in database", %{conn: conn} do
      {view, result} = provision_and_enter_edit_mode(conn)

      view
      |> form("form", %{text: "Change the tagline to something fresh"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Updated tagline"
      assert html =~ "1 of 10 edits used"

      # Verify DB was updated
      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert is_binary(config.tagline)
      assert String.length(config.tagline) > 0
    end

    test "phone edit updates SiteConfig in database", %{conn: conn} do
      {view, result} = provision_and_enter_edit_mode(conn)

      view
      |> form("form", %{text: "Change phone to 555-8888"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Updated phone"
      assert html =~ "555-8888"

      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.phone == "555-8888"
    end

    test "service addition creates service in tenant", %{conn: conn} do
      {view, result} = provision_and_enter_edit_mode(conn)

      view
      |> form("form", %{text: "Add a Demolition service"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Added"
      assert html =~ "Demolition"

      services = Ash.read!(Service, tenant: result.tenant)
      assert Enum.any?(services, &(&1.title == "Demolition"))
    end

    test "multiple edits increment counter correctly", %{conn: conn} do
      {view, _result} = provision_and_enter_edit_mode(conn)

      view
      |> form("form", %{text: "Change phone to 555-1111"})
      |> render_submit()

      Process.sleep(50)

      view
      |> form("form", %{text: "Change phone to 555-2222"})
      |> render_submit()

      Process.sleep(50)
      html = render(view)

      assert html =~ "2 of 10 edits used"
    end
  end

  describe "go live and tenant site verification" do
    test "go live finalizes session with admin link", %{conn: conn} do
      {view, _result} = provision_and_enter_edit_mode(conn)

      view |> element("#preview-panel-desktop button", "Looks good") |> render_click()

      Process.sleep(50)
      html = render(view)

      assert html =~ "finalized and live"
      assert html =~ "admin panel"
      assert html =~ "Your site is finalized"
      # Input form replaced
      refute html =~ ~s(placeholder="Request a change...")
    end

    test "tenant landing page renders with provisioned content", %{conn: conn} do
      {_view, result} = provision_and_enter_edit_mode(conn)

      # Point operator config at the new tenant's slug
      original_operator = Application.get_env(:haul, :operator)

      Application.put_env(
        :haul,
        :operator,
        Keyword.merge(original_operator || [], slug: result.company.slug)
      )

      on_exit(fn ->
        Application.put_env(:haul, :operator, original_operator)
      end)

      # GET / should render operator landing page with generated content
      tenant_conn = get(build_conn(), ~p"/")
      html = html_response(tenant_conn, 200)

      # Business info from provisioning
      assert html =~ "555-7777"
      assert html =~ "qa@pipeline.example.com"
      assert html =~ "QA Metro"

      # Services section
      assert html =~ "What We Do"
    end

    test "tenant scan page renders after provisioning", %{conn: conn} do
      {_view, result} = provision_and_enter_edit_mode(conn)

      original_operator = Application.get_env(:haul, :operator)

      Application.put_env(
        :haul,
        :operator,
        Keyword.merge(original_operator || [], slug: result.company.slug)
      )

      on_exit(fn ->
        Application.put_env(:haul, :operator, original_operator)
      end)

      # /scan should render without error
      {:ok, _view, html} = live(build_conn(), "/scan")
      assert html =~ "Scan"
    end

    test "tenant booking form renders after provisioning", %{conn: conn} do
      {_view, result} = provision_and_enter_edit_mode(conn)

      original_operator = Application.get_env(:haul, :operator)

      Application.put_env(
        :haul,
        :operator,
        Keyword.merge(original_operator || [], slug: result.company.slug)
      )

      on_exit(fn ->
        Application.put_env(:haul, :operator, original_operator)
      end)

      # /book should render the booking form
      {:ok, _view, html} = live(build_conn(), "/book")
      assert html =~ "Book"
    end

    test "edited content appears on tenant landing page", %{conn: conn} do
      {view, result} = provision_and_enter_edit_mode(conn)

      # Edit phone to a new number
      view
      |> form("form", %{text: "Change phone to 555-999-4321"})
      |> render_submit()

      Process.sleep(100)

      # Point operator config at the new tenant's slug
      original_operator = Application.get_env(:haul, :operator)

      Application.put_env(
        :haul,
        :operator,
        Keyword.merge(original_operator || [], slug: result.company.slug)
      )

      on_exit(fn ->
        Application.put_env(:haul, :operator, original_operator)
      end)

      # Verify landing page shows the edited phone
      tenant_conn = get(build_conn(), ~p"/")
      html = html_response(tenant_conn, 200)

      assert html =~ "555-999-4321"
    end
  end

  describe "mobile preview in edit mode" do
    test "mobile preview toggle shows and hides preview panel", %{conn: conn} do
      {view, _result} = provision_and_enter_edit_mode(conn)

      # After provisioning, show_profile? is true — shows "Hide Preview"
      html = render(view)
      assert html =~ "Hide Preview"

      # Toggle to hide
      html = render_click(view, "toggle_profile")
      assert html =~ "Show Preview"

      # Toggle to show again
      html = render_click(view, "toggle_profile")
      assert html =~ "Hide Preview"
    end
  end
end
