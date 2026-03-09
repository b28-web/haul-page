defmodule HaulWeb.ChatQATest do
  @moduledoc """
  Browser QA for conversational onboarding chat (T-019-06).
  End-to-end verification of the chat UX at /start:
  full conversation flow, streaming, profile extraction,
  mobile toggle, provisioning, persistence, and fallback paths.
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.AI.Chat.Sandbox, as: ChatSandbox

  setup do
    clear_rate_limits()
    ChatSandbox.clear_response()
    ChatSandbox.clear_error()
    :ok
  end

  describe "chat UI layout" do
    test "renders header with title and manual signup link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "Get Started"
      assert html =~ "Tell us about your business"
      assert html =~ "or sign up manually"
      assert html =~ ~s(href="/app/signup")
    end

    test "shows welcome message when no messages exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "help set up your business page"
      assert html =~ "Tell me about your junk removal business"
    end

    test "renders input field with placeholder and Send button", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ ~s(placeholder="Type a message...")
      assert html =~ "Send"
    end

    test "renders 'Prefer a form?' fallback link below input", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "Prefer a form?"
      assert html =~ "Fill out a form instead"
      assert html =~ ~s(href="/app/signup")
    end

    test "profile sidebar shows empty state with 0 of 7 fields", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "Your Profile"
      assert html =~ "0 of 7 fields collected"
      assert html =~ "Start chatting to build your profile"
    end
  end

  describe "full conversation flow" do
    test "multi-turn conversation builds profile progressively", %{conn: conn} do
      ChatSandbox.set_response("Great! What services do you offer?")
      {:ok, view, _html} = live(conn, "/start")

      # Turn 1: introduce business
      view
      |> form("form", %{text: "I run a junk removal business called Joe's Hauling in Portland"})
      |> render_submit()

      # Wait for streaming + extraction
      Process.sleep(1500)
      html = render(view)

      # User message appears
      assert html =~ "Joe&#39;s Hauling in Portland"
      # AI response appears
      assert html =~ "Great! What services do you offer?"
      # Sandbox extraction returns full profile — all 7 fields filled
      assert html =~ "Junk &amp; Handy"
      assert html =~ "7 of 7 fields collected"

      # Turn 2: provide more info
      ChatSandbox.set_response("Sounds good! Anything else?")

      view
      |> form("form", %{text: "We do junk removal, yard waste, and garage cleanouts"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      # Both turns' messages present
      assert html =~ "Joe&#39;s Hauling"
      assert html =~ "junk removal, yard waste"
      assert html =~ "Sounds good! Anything else?"
    end

    test "user messages are right-aligned, AI messages are left-aligned", %{conn: conn} do
      ChatSandbox.set_response("Hello!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hi there"})
      |> render_submit()

      Process.sleep(500)
      html = render(view)

      # User bubble: right-aligned with zinc-700 bg
      assert html =~ "justify-end"
      assert html =~ "bg-zinc-700"
      # AI bubble: left-aligned with card bg
      assert html =~ "justify-start"
      assert html =~ "bg-card"
    end
  end

  describe "streaming UX" do
    test "input is disabled during streaming", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      html =
        view
        |> form("form", %{text: "Hello"})
        |> render_submit()

      # Input should be disabled immediately after submit
      assert html =~ "disabled"
    end

    test "input re-enables after streaming completes", %{conn: conn} do
      ChatSandbox.set_response("Hi!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello"})
      |> render_submit()

      Process.sleep(500)
      html = render(view)

      # Input should not be disabled after streaming completes
      # (input element without disabled attribute)
      refute html =~ ~s(name="text" value="" phx-change="update_input" placeholder="Type a message..." autocomplete="off" disabled)
    end

    test "typing indicator has animated dots", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      html =
        view
        |> form("form", %{text: "Hello"})
        |> render_submit()

      # Typing indicator should show bouncing dots (before content arrives)
      assert html =~ "animate-bounce"
    end
  end

  describe "profile panel" do
    test "populates all fields after extraction", %{conn: conn} do
      ChatSandbox.set_response("Got it!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "We're Junk & Handy in Portland"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      # Sandbox default profile fields
      assert html =~ "Junk &amp; Handy"
      assert html =~ "Mike Johnson"
      assert html =~ "(555) 123-4567"
      assert html =~ "mike@junkandhandy.com"
      assert html =~ "Portland Metro Area"
    end

    test "services list renders individual service names", %{conn: conn} do
      ChatSandbox.set_response("Nice!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "We do junk removal"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      assert html =~ "Junk Removal"
      assert html =~ "Yard Waste"
      assert html =~ "Garage Cleanouts"
    end

    test "differentiators list renders", %{conn: conn} do
      ChatSandbox.set_response("Awesome!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "We recycle 80%"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      assert html =~ "What Sets You Apart"
      assert html =~ "Same-day service available"
      assert html =~ "Licensed and insured"
    end

    test "progress bar width reflects completeness percentage", %{conn: conn} do
      ChatSandbox.set_response("Great!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      # Sandbox fills all 7 fields — progress bar at 100%
      assert html =~ "width: 100%"
    end

    test "shows profile complete CTA when required fields present", %{conn: conn} do
      ChatSandbox.set_response("Perfect!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "I'm Mike from Junk & Handy"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      assert html =~ "Your profile is complete!"
      assert html =~ "Build my site"
    end
  end

  describe "mobile profile toggle" do
    test "toggle button not visible before profile exists", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      refute html =~ "View Profile"
      refute html =~ "Hide Profile"
    end

    test "toggle button appears after extraction and toggles panel visibility", %{conn: conn} do
      ChatSandbox.set_response("Nice!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "I'm Mike from Junk & Handy"})
      |> render_submit()

      Process.sleep(1500)

      # After extraction, show_profile? is set to true — toggle shows "Hide Profile"
      html = render(view)
      assert html =~ "Hide Profile"

      # Toggle to hide
      html = render_click(view, "toggle_profile")
      assert html =~ "View Profile"

      # Toggle to show again
      html = render_click(view, "toggle_profile")
      assert html =~ "Hide Profile"
    end
  end

  describe "provisioning flow" do
    test "Build my site triggers provisioning state", %{conn: conn} do
      ChatSandbox.set_response("Ready!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "I'm Mike"})
      |> render_submit()

      Process.sleep(1500)

      # Click "Build my site"
      html = render_click(view, "provision_site")
      assert html =~ "Building your site..."
    end

    test "provisioning_complete shows site URL", %{conn: conn} do
      ChatSandbox.set_response("Ready!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "I'm Mike"})
      |> render_submit()

      Process.sleep(1500)

      # Start provisioning
      render_click(view, "provision_site")

      # Simulate completion
      send(view.pid, {:provisioning_complete, %{site_url: "https://test.example.com", company_name: "Junk & Handy", duration_ms: 15000}})
      Process.sleep(50)
      html = render(view)

      assert html =~ "Your site is live!"
      assert html =~ "View your site"
      assert html =~ "https://test.example.com"
    end

    test "provisioning_failed shows error and allows retry", %{conn: conn} do
      ChatSandbox.set_response("Ready!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "I'm Mike"})
      |> render_submit()

      Process.sleep(1500)

      # Start provisioning
      render_click(view, "provision_site")

      # Simulate failure
      send(view.pid, {:provisioning_failed, %{step: :create_company, reason: "slug taken"}})
      Process.sleep(50)
      html = render(view)

      assert html =~ "Something went wrong building your site"
      # Button should be available again (provisioning? set back to false)
      assert html =~ "Build my site"
    end
  end

  describe "conversation persistence" do
    test "conversation is found when reconnecting with same session_id", %{conn: conn} do
      ChatSandbox.set_response("Hello back!")
      session_id = Ecto.UUID.generate()

      # First connection: send a message
      conn1 = Plug.Test.init_test_session(conn, %{"chat_session_id" => session_id})
      {:ok, view, _html} = live(conn1, "/start")

      view
      |> form("form", %{text: "Hi, I'm starting a business"})
      |> render_submit()

      Process.sleep(500)

      # Second connection: same session_id
      conn2 =
        build_conn()
        |> Plug.Test.init_test_session(%{"chat_session_id" => session_id})

      {:ok, _view2, html2} = live(conn2, "/start")

      # The AI response is restored (last persisted message survives)
      assert html2 =~ "Hello back!"
      # Chat UI renders — not redirected, not blank
      assert html2 =~ "Get Started"
    end
  end

  describe "error recovery" do
    test "redirects to /app/signup when chat is not configured", %{conn: conn} do
      original = Application.get_env(:haul, :chat_available, true)
      Application.put_env(:haul, :chat_available, false)

      result = live(conn, "/start")
      assert {:error, {:redirect, %{to: "/app/signup"}}} = result

      Application.put_env(:haul, :chat_available, original)
    end

    test "first message AI error redirects to signup with flash", %{conn: conn} do
      ChatSandbox.set_error("API timeout")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello"})
      |> render_submit()

      Process.sleep(100)
      flash = assert_redirect(view, "/app/signup")
      assert flash["error"] =~ "temporarily unavailable"
    end

    test "later message AI error stays on page with flash", %{conn: conn} do
      ChatSandbox.set_response("Hi there!")
      {:ok, view, _html} = live(conn, "/start")

      # Send first message successfully
      view |> form("form", %{text: "Hello"}) |> render_submit()
      Process.sleep(500)

      # Send second message successfully
      view |> form("form", %{text: "More info"}) |> render_submit()
      Process.sleep(500)

      # Simulate error after multiple messages
      send(view.pid, {:ai_error, "Connection reset"})
      Process.sleep(50)
      html = render(view)

      # Page still shows chat UI — no redirect
      assert html =~ "Get Started"
      assert html =~ "Type a message"
    end
  end

  describe "rate limiting" do
    test "shows message limit error at 50 messages", %{conn: conn} do
      ChatSandbox.set_response("OK")
      {:ok, view, _html} = live(conn, "/start")

      # Send 50 messages
      for i <- 1..50 do
        view
        |> form("form", %{text: "Message #{i}"})
        |> render_submit()

        Process.sleep(50)
      end

      # 51st should be rejected
      html =
        view
        |> form("form", %{text: "One more"})
        |> render_submit()

      assert html =~ "Message limit reached"
    end
  end
end
