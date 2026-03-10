defmodule HaulWeb.PreviewEditTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.AI.Chat.Sandbox, as: ChatSandbox
  alias Haul.AI.Conversation
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.Content.{Service, SiteConfig}

  @profile %OperatorProfile{
    business_name: "Preview Test Co",
    owner_name: "Test Owner",
    phone: "555-0000",
    email: "preview@example.com",
    service_area: "Test City",
    tagline: "We test it all!",
    years_in_business: 3,
    services: [
      %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal},
      %ServiceOffering{name: "Yard Waste", description: nil, category: :yard_waste}
    ],
    differentiators: ["Fast", "Reliable"]
  }

  # Provision the tenant ONCE for all tests. DDL (CREATE SCHEMA + migrations) is
  # expensive (~250ms). Per-test content modifications are rolled back by the sandbox.
  setup_all do
    # setup_all runs outside the sandbox — use :auto mode for DDL
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    {:ok, conv} =
      Conversation
      |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
      |> Ash.create()

    {:ok, result} = Haul.AI.Provisioner.from_profile(@profile, conv.id)

    # Restore manual mode for per-test sandboxing
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "tenant_preview-test-co" CASCADE))
      Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
    end)

    %{provision_result: result}
  end

  setup do
    clear_rate_limits()
    ChatSandbox.clear_response()
    ChatSandbox.clear_error()
    :ok
  end

  defp with_operator_slug(slug) do
    original = Application.get_env(:haul, :operator)
    Application.put_env(:haul, :operator, Keyword.merge(original || [], slug: slug))
    on_exit(fn -> Application.put_env(:haul, :operator, original) end)
  end

  defp enter_edit_mode(conn, result) do
    {:ok, view, _html} = live(conn, "/start")

    # Set the profile (normally set during extraction phase before provisioning)
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

  describe "edit mode transition" do
    test "shows preview panel after provisioning", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)
      html = render(view)

      assert html =~ "Site Preview"
      assert html =~ "preview-test-co"
      assert html =~ "Looks good"
      assert html =~ "0 of 10 edits used"
    end

    test "shows edit instructions in chat", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)
      html = render(view)

      assert html =~ "take a look"
      assert html =~ "Request changes"
    end

    test "header changes to Preview & Edit", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)
      html = render(view)

      assert html =~ "Preview &amp; Edit"
    end
  end

  describe "direct edits" do
    test "updates phone number via chat", %{conn: conn, provision_result: provision_result} do
      {view, result} = enter_edit_mode(conn, provision_result)

      view
      |> form("form", %{text: "Change phone to 555-9999"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Updated phone"
      assert html =~ "555-9999"

      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.phone == "555-9999"
    end

    test "updates email via chat", %{conn: conn, provision_result: provision_result} do
      {view, result} = enter_edit_mode(conn, provision_result)

      view
      |> form("form", %{text: "Email should be new@example.com"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Updated email"

      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.email == "new@example.com"
    end

    test "increments edit count", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

      view
      |> form("form", %{text: "Change phone to 555-1111"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "1 of 10 edits used"
    end
  end

  describe "service management" do
    test "adds a new service", %{conn: conn, provision_result: provision_result} do
      {view, result} = enter_edit_mode(conn, provision_result)

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

    test "removes a service (soft delete)", %{conn: conn, provision_result: provision_result} do
      {view, result} = enter_edit_mode(conn, provision_result)

      # First, add a test service
      Service
      |> Ash.Changeset.for_create(
        :add,
        %{
          title: "Test Removal",
          description: "Test desc",
          icon: "fa-test"
        },
        tenant: result.tenant
      )
      |> Ash.create!()

      view
      |> form("form", %{text: "Remove Test Removal"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Removed"

      services = Ash.read!(Service, tenant: result.tenant)
      svc = Enum.find(services, &(&1.title == "Test Removal"))
      assert svc.active == false
    end
  end

  describe "regeneration" do
    test "regenerates tagline", %{conn: conn, provision_result: provision_result} do
      {view, result} = enter_edit_mode(conn, provision_result)

      view
      |> form("form", %{text: "Change the tagline to something catchy"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Updated tagline"

      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert is_binary(config.tagline)
      assert String.length(config.tagline) > 0
    end
  end

  describe "edit limit" do
    test "enforces max 10 edit rounds", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

      # Apply 10 edits
      for i <- 1..10 do
        phone = "555-#{String.pad_leading(to_string(i), 4, "0")}"

        view
        |> form("form", %{text: "Change phone to #{phone}"})
        |> render_submit()

        Process.sleep(50)
      end

      # 11th edit should be rejected
      view
      |> form("form", %{text: "Change phone to 555-9999"})
      |> render_submit()

      Process.sleep(50)
      html = render(view)

      assert html =~ "edit limit"
      assert html =~ "admin panel"
    end
  end

  describe "go live" do
    test "finalizes session", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

      view |> element("#preview-panel-desktop button", "Looks good") |> render_click()

      Process.sleep(50)
      html = render(view)

      assert html =~ "finalized and live"
      assert html =~ "admin panel"
      # Input should be replaced with finalized message
      assert html =~ "Your site is finalized"
    end

    test "disables further input after finalize", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

      view |> element("#preview-panel-desktop button", "Looks good") |> render_click()
      Process.sleep(50)

      html = render(view)

      # The form should be gone — replaced by finalized message
      assert html =~ "Your site is finalized"
      refute html =~ ~s(placeholder="Request a change...")
    end
  end

  describe "unknown edits" do
    test "returns help text for unrecognized messages", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

      view
      |> form("form", %{text: "I like the color blue"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "not sure what to change"
    end
  end

  describe "pre-provision state" do
    test "chat UI renders and accepts messages before provisioning", %{conn: conn, provision_result: _provision_result} do
      ChatSandbox.set_response("Welcome! Tell me about your business.")
      {:ok, view, html} = live(conn, "/start")

      assert html =~ "Get Started"
      assert html =~ "Type a message..."

      view
      |> form("form", %{text: "I run Preview Test Co in Test City"})
      |> render_submit()

      Process.sleep(200)
      html = render(view)

      assert html =~ "Preview Test Co"
      assert html =~ "Welcome! Tell me about your business."
    end

    test "shows building message during provisioning", %{conn: conn, provision_result: _provision_result} do
      ChatSandbox.set_response("Got it!")
      {:ok, view, _html} = live(conn, "/start")

      send(view.pid, {:extraction_result, {:ok, @profile}})
      Process.sleep(50)

      html = render_click(view, "provision_site")
      assert html =~ "Building your site"
    end
  end

  describe "edit instructions" do
    test "provisioning_complete message shows edit instructions", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)
      html = render(view)

      assert html =~ "take a look"
      assert html =~ "Request changes"
    end
  end

  describe "multiple edits" do
    test "multiple edits increment counter correctly", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

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

  describe "tenant page verification" do
    test "tenant landing page renders with provisioned content", %{conn: conn, provision_result: provision_result} do
      {_view, result} = enter_edit_mode(conn, provision_result)
      with_operator_slug(result.company.slug)

      tenant_conn = get(build_conn(), ~p"/")
      html = html_response(tenant_conn, 200)

      assert html =~ "555-0000"
      assert html =~ "preview@example.com"
      assert html =~ "Test City"
      assert html =~ "What We Do"
    end

    test "tenant scan page renders after provisioning", %{conn: conn, provision_result: provision_result} do
      {_view, result} = enter_edit_mode(conn, provision_result)
      with_operator_slug(result.company.slug)

      {:ok, _view, html} = live(build_conn(), "/scan")
      assert html =~ "Scan"
    end

    test "tenant booking form renders after provisioning", %{conn: conn, provision_result: provision_result} do
      {_view, result} = enter_edit_mode(conn, provision_result)
      with_operator_slug(result.company.slug)

      {:ok, _view, html} = live(build_conn(), "/book")
      assert html =~ "Book"
    end
  end

  describe "edit persistence" do
    test "edited content appears on tenant landing page", %{conn: conn, provision_result: provision_result} do
      {view, result} = enter_edit_mode(conn, provision_result)

      view
      |> form("form", %{text: "Change phone to 555-999-4321"})
      |> render_submit()

      Process.sleep(100)
      with_operator_slug(result.company.slug)

      tenant_conn = get(build_conn(), ~p"/")
      html = html_response(tenant_conn, 200)

      assert html =~ "555-999-4321"
    end
  end

  describe "mobile preview toggle" do
    test "mobile preview toggle shows and hides preview panel", %{conn: conn, provision_result: provision_result} do
      {view, _result} = enter_edit_mode(conn, provision_result)

      html = render(view)
      assert html =~ "Hide Preview"

      html = render_click(view, "toggle_profile")
      assert html =~ "Show Preview"

      html = render_click(view, "toggle_profile")
      assert html =~ "Hide Preview"
    end
  end
end
