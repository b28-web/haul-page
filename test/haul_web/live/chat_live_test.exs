defmodule HaulWeb.ChatLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.AI.Chat.Sandbox, as: ChatSandbox

  setup do
    clear_rate_limits()
    ChatSandbox.clear_response()
    ChatSandbox.clear_error()
    :ok
  end

  describe "mount" do
    test "renders chat page at /start", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "Get Started"
      assert html =~ "Tell us about your business"
      assert html =~ "Type a message..."
    end

    test "starts with empty message list", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      # Shows welcome text when no messages
      assert html =~ "help set up your business page"
    end

    test "renders profile sidebar with empty state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "Your Profile"
      assert html =~ "0 of 7 fields collected"
      assert html =~ "Start chatting to build your profile"
    end
  end

  describe "send_message" do
    test "sends a user message and receives AI response", %{conn: conn} do
      ChatSandbox.set_response("Great to meet you!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello, I run a junk removal company"})
      |> render_submit()

      # Wait for streaming response to complete
      Process.sleep(500)
      html = render(view)

      # User message appears
      assert html =~ "Hello, I run a junk removal company"
      # AI response appears
      assert html =~ "Great to meet you!"
    end

    test "rejects empty messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      html =
        view
        |> form("form", %{text: ""})
        |> render_submit()

      # No messages should appear
      assert html =~ "help set up your business page"
    end

    test "rejects whitespace-only messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      html =
        view
        |> form("form", %{text: "   "})
        |> render_submit()

      assert html =~ "help set up your business page"
    end

    test "clears input after sending", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello"})
      |> render_submit()

      # Wait for streaming to complete
      Process.sleep(300)
      html = render(view)

      # Input should be cleared
      refute html =~ ~s(value="Hello")
    end
  end

  describe "rate limiting" do
    test "enforces max message limit", %{conn: conn} do
      ChatSandbox.set_response("OK")
      {:ok, view, _html} = live(conn, "/start")

      # Send 50 messages, waiting for each stream to complete
      for i <- 1..50 do
        view
        |> form("form", %{text: "Message #{i}"})
        |> render_submit()

        # Wait for streaming to complete before next message
        Process.sleep(50)
      end

      # 51st message should be rejected
      html =
        view
        |> form("form", %{text: "One more"})
        |> render_submit()

      assert html =~ "Message limit reached"
    end
  end

  describe "streaming" do
    test "disables input during streaming", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      html =
        view
        |> form("form", %{text: "Hello"})
        |> render_submit()

      # Input should be disabled immediately after submit
      assert html =~ "disabled"
    end

    test "re-enables input after streaming completes", %{conn: conn} do
      ChatSandbox.set_response("Hi!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello"})
      |> render_submit()

      # Wait for streaming to complete
      Process.sleep(300)
      html = render(view)

      # The text input should not be disabled after streaming completes
      # (the button may still be disabled because input is empty)
      refute html =~
               ~s(<input type="text" name="text" value="" phx-change="update_input" placeholder="Type a message..." autocomplete="off" disabled="")
    end
  end

  describe "live extraction" do
    test "profile panel updates after extraction completes", %{conn: conn} do
      ChatSandbox.set_response("Nice! Tell me more.")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hi, I'm Mike from Junk & Handy"})
      |> render_submit()

      # Wait for streaming + extraction debounce (800ms) + extraction task
      Process.sleep(1500)
      html = render(view)

      # Sandbox default returns "Junk & Handy" as business name
      assert html =~ "Junk &amp; Handy"
      assert html =~ "Mike Johnson"
      assert html =~ "(555) 123-4567"
      assert html =~ "mike@junkandhandy.com"
    end

    test "completeness indicator updates with extracted fields", %{conn: conn} do
      ChatSandbox.set_response("Got it!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "We do junk removal in Portland"})
      |> render_submit()

      # Wait for extraction to complete
      Process.sleep(1500)
      html = render(view)

      # Sandbox default profile has all 7 fields filled
      assert html =~ "7 of 7 fields collected"
    end

    test "services list renders in profile panel", %{conn: conn} do
      ChatSandbox.set_response("Great!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "We offer junk removal and cleanouts"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      # Sandbox default includes these services
      assert html =~ "Junk Removal"
      assert html =~ "Yard Waste"
      assert html =~ "Garage Cleanouts"
    end

    test "differentiators render in profile panel", %{conn: conn} do
      ChatSandbox.set_response("Awesome!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "We recycle 80% of what we haul"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      assert html =~ "Same-day service available"
      assert html =~ "Licensed and insured"
    end

    test "profile complete CTA appears when all required fields present", %{conn: conn} do
      ChatSandbox.set_response("Perfect!")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "I'm Mike, we're Junk & Handy, call us at 555-1234"})
      |> render_submit()

      Process.sleep(1500)
      html = render(view)

      # Sandbox returns complete profile — CTA should appear
      assert html =~ "Your profile is complete!"
      assert html =~ "Build my site"
    end

    test "extraction errors do not show in UI", %{conn: conn} do
      ChatSandbox.set_response("Tell me more!")
      {:ok, view, _html} = live(conn, "/start")

      # Send extraction error via handle_info directly
      send(view.pid, {:extraction_result, {:error, :timeout}})
      Process.sleep(50)
      html = render(view)

      # No error should be visible
      refute html =~ "error"
      refute html =~ "timeout"
      # Profile should remain nil
      assert html =~ "Start chatting to build your profile"
    end

    test "extraction crash is handled silently", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start")

      # Simulate a DOWN message from extraction task
      fake_ref = make_ref()
      send(view.pid, {:DOWN, fake_ref, :process, self(), :killed})
      Process.sleep(50)
      html = render(view)

      # No crash, page still works
      assert html =~ "Your Profile"
    end
  end

  describe "fallback links" do
    test "renders manual signup link in header", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "or sign up manually"
      assert html =~ ~s(href="/app/signup")
    end

    test "renders form fallback link below input", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/start")

      assert html =~ "Fill out a form instead"
    end
  end

  describe "llm not configured" do
    test "redirects to /app/signup when chat_available is false", %{conn: conn} do
      # Temporarily disable chat
      original = Application.get_env(:haul, :chat_available, true)
      Application.put_env(:haul, :chat_available, false)

      result = live(conn, "/start")
      assert {:error, {:redirect, %{to: "/app/signup"}}} = result

      # Restore
      Application.put_env(:haul, :chat_available, original)
    end
  end

  describe "first message error" do
    test "redirects to /app/signup with flash on first message error", %{conn: conn} do
      ChatSandbox.set_error("API error")
      {:ok, view, _html} = live(conn, "/start")

      view
      |> form("form", %{text: "Hello"})
      |> render_submit()

      # Wait for error to be received
      Process.sleep(100)

      # The LiveView should have redirected
      flash = assert_redirect(view, "/app/signup")
      assert flash["error"] =~ "temporarily unavailable"
    end

    test "stays on page for later message errors instead of redirecting", %{conn: conn} do
      ChatSandbox.set_response("Hi there!")
      {:ok, view, _html} = live(conn, "/start")

      # Send two messages so message_count > 1
      view |> form("form", %{text: "Hello"}) |> render_submit()
      Process.sleep(500)
      view |> form("form", %{text: "More info"}) |> render_submit()
      Process.sleep(500)

      # Simulate AI error after multiple messages (message_count == 2)
      send(view.pid, {:ai_error, "API error"})
      Process.sleep(50)
      html = render(view)

      # Should stay on page (not redirect) — page still shows chat UI
      assert html =~ "Get Started"
      assert html =~ "Type a message"
    end
  end
end
