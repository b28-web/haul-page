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

  defp enter_edit_mode(conn) do
    {:ok, view, _html} = live(conn, "/start")

    # Create a conversation and provision a site
    {:ok, conv} =
      Conversation
      |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
      |> Ash.create()

    {:ok, result} = Haul.AI.Provisioner.from_profile(@profile, conv.id)

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
    test "shows preview panel after provisioning", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)
      html = render(view)

      assert html =~ "Site Preview"
      assert html =~ "preview-test-co"
      assert html =~ "Looks good"
      assert html =~ "0 of 10 edits used"
    end

    test "shows edit instructions in chat", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)
      html = render(view)

      assert html =~ "take a look"
      assert html =~ "Request changes"
    end

    test "header changes to Preview & Edit", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)
      html = render(view)

      assert html =~ "Preview &amp; Edit"
    end
  end

  describe "direct edits" do
    test "updates phone number via chat", %{conn: conn} do
      {view, result} = enter_edit_mode(conn)

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

    test "updates email via chat", %{conn: conn} do
      {view, result} = enter_edit_mode(conn)

      view
      |> form("form", %{text: "Email should be new@example.com"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "Updated email"

      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.email == "new@example.com"
    end

    test "increments edit count", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)

      view
      |> form("form", %{text: "Change phone to 555-1111"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "1 of 10 edits used"
    end
  end

  describe "service management" do
    test "adds a new service", %{conn: conn} do
      {view, result} = enter_edit_mode(conn)

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

    test "removes a service (soft delete)", %{conn: conn} do
      {view, result} = enter_edit_mode(conn)

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
    test "regenerates tagline", %{conn: conn} do
      {view, result} = enter_edit_mode(conn)

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
    test "enforces max 10 edit rounds", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)

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
    test "finalizes session", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)

      view |> element("#preview-panel-desktop button", "Looks good") |> render_click()

      Process.sleep(50)
      html = render(view)

      assert html =~ "finalized and live"
      assert html =~ "admin panel"
      # Input should be replaced with finalized message
      assert html =~ "Your site is finalized"
    end

    test "disables further input after finalize", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)

      view |> element("#preview-panel-desktop button", "Looks good") |> render_click()
      Process.sleep(50)

      html = render(view)

      # The form should be gone — replaced by finalized message
      assert html =~ "Your site is finalized"
      refute html =~ ~s(placeholder="Request a change...")
    end
  end

  describe "unknown edits" do
    test "returns help text for unrecognized messages", %{conn: conn} do
      {view, _result} = enter_edit_mode(conn)

      view
      |> form("form", %{text: "I like the color blue"})
      |> render_submit()

      Process.sleep(100)
      html = render(view)

      assert html =~ "not sure what to change"
    end
  end
end
