defmodule HaulWeb.ChatLiveUnitTest do
  use ExUnit.Case, async: true

  import Haul.Test.LiveHelpers

  alias HaulWeb.ChatLive

  # Helpers for building ChatLive-specific sockets

  defp chat_socket(overrides \\ %{}) do
    defaults = %{
      input: "",
      streaming?: false,
      finalized?: false,
      edit_mode?: false,
      show_profile?: false,
      messages: [],
      message_count: 0,
      session_id: "test-session",
      task_ref: nil,
      extraction_ref: nil,
      provisioning?: false,
      provisioned_url: nil,
      tenant: nil,
      company: nil,
      profile_complete?: false,
      conversation: nil,
      profile: nil
    }

    build_socket(Map.merge(defaults, overrides))
  end

  describe "update_input event" do
    test "sets the input assign" do
      socket = chat_socket()

      assert {:noreply, socket} =
               apply_event(ChatLive, "update_input", %{"text" => "hello"}, socket)

      assert socket.assigns.input == "hello"
    end

    test "replaces existing input" do
      socket = chat_socket(%{input: "old text"})

      assert {:noreply, socket} =
               apply_event(ChatLive, "update_input", %{"text" => "new text"}, socket)

      assert socket.assigns.input == "new text"
    end

    test "handles empty text" do
      socket = chat_socket(%{input: "something"})
      assert {:noreply, socket} = apply_event(ChatLive, "update_input", %{"text" => ""}, socket)
      assert socket.assigns.input == ""
    end

    test "ignores params without text key" do
      socket = chat_socket(%{input: "keep this"})
      assert {:noreply, socket} = apply_event(ChatLive, "update_input", %{}, socket)
      assert socket.assigns.input == "keep this"
    end
  end

  describe "toggle_profile event" do
    test "toggles false to true" do
      socket = chat_socket(%{show_profile?: false})
      assert {:noreply, socket} = apply_event(ChatLive, "toggle_profile", %{}, socket)
      assert socket.assigns.show_profile? == true
    end

    test "toggles true to false" do
      socket = chat_socket(%{show_profile?: true})
      assert {:noreply, socket} = apply_event(ChatLive, "toggle_profile", %{}, socket)
      assert socket.assigns.show_profile? == false
    end
  end

  describe "go_live event" do
    test "sets finalized and appends message" do
      socket = chat_socket(%{finalized?: false, messages: []})
      assert {:noreply, socket} = apply_event(ChatLive, "go_live", %{}, socket)
      assert socket.assigns.finalized? == true
      assert length(socket.assigns.messages) == 1
      assert hd(socket.assigns.messages).role == :assistant
      assert hd(socket.assigns.messages).content =~ "finalized and live"
    end

    test "no-op when already finalized" do
      socket = chat_socket(%{finalized?: true, messages: [%{role: :user, content: "hi"}]})
      assert {:noreply, socket} = apply_event(ChatLive, "go_live", %{}, socket)
      assert socket.assigns.finalized? == true
      # No message appended
      assert length(socket.assigns.messages) == 1
    end

    test "preserves existing messages" do
      existing = [%{id: "1", role: :user, content: "hello"}]
      socket = chat_socket(%{finalized?: false, messages: existing})
      assert {:noreply, socket} = apply_event(ChatLive, "go_live", %{}, socket)
      assert length(socket.assigns.messages) == 2
      assert hd(socket.assigns.messages).content == "hello"
    end
  end

  describe "send_message guards" do
    test "rejects empty text" do
      socket = chat_socket()
      assert {:noreply, socket} = apply_event(ChatLive, "send_message", %{"text" => ""}, socket)
      # Socket unchanged (no flash, no message added)
      assert socket.assigns.messages == []
    end

    test "rejects whitespace-only text" do
      socket = chat_socket()

      assert {:noreply, socket} =
               apply_event(ChatLive, "send_message", %{"text" => "   "}, socket)

      assert socket.assigns.messages == []
    end

    test "rejects when streaming" do
      socket = chat_socket(%{streaming?: true})

      assert {:noreply, socket} =
               apply_event(ChatLive, "send_message", %{"text" => "hello"}, socket)

      assert socket.assigns.messages == []
    end

    test "rejects when finalized" do
      socket = chat_socket(%{finalized?: true})

      assert {:noreply, socket} =
               apply_event(ChatLive, "send_message", %{"text" => "hello"}, socket)

      assert socket.assigns.messages == []
    end
  end

  describe "handle_info :ai_chunk" do
    test "appends text to last assistant message" do
      messages = [
        %{id: "1", role: :user, content: "hi"},
        %{id: "2", role: :assistant, content: "Hello"}
      ]

      socket = chat_socket(%{messages: messages})
      assert {:noreply, socket} = apply_info(ChatLive, {:ai_chunk, " there!"}, socket)

      last_msg = List.last(socket.assigns.messages)
      assert last_msg.content == "Hello there!"
    end

    test "does not crash when no assistant message exists" do
      messages = [%{id: "1", role: :user, content: "hi"}]
      socket = chat_socket(%{messages: messages})
      assert {:noreply, socket} = apply_info(ChatLive, {:ai_chunk, "text"}, socket)
      # Messages unchanged (no assistant to append to)
      assert length(socket.assigns.messages) == 1
    end
  end

  describe "handle_info :provisioning_complete" do
    test "updates provisioning state" do
      socket = chat_socket(%{provisioning?: true, messages: []})

      result = %{
        site_url: "https://test.haulpage.com",
        tenant: "tenant_test",
        company: %{name: "Test Co"}
      }

      assert {:noreply, socket} = apply_info(ChatLive, {:provisioning_complete, result}, socket)
      assert socket.assigns.provisioning? == false
      assert socket.assigns.provisioned_url == "https://test.haulpage.com"
      assert socket.assigns.edit_mode? == true
      assert socket.assigns.tenant == "tenant_test"
      assert socket.assigns.show_profile? == true
    end

    test "appends preview message" do
      socket = chat_socket(%{provisioning?: true, messages: []})
      result = %{site_url: "https://test.haulpage.com", tenant: "t"}

      assert {:noreply, socket} = apply_info(ChatLive, {:provisioning_complete, result}, socket)
      assert length(socket.assigns.messages) == 1
      assert hd(socket.assigns.messages).role == :assistant
      assert hd(socket.assigns.messages).content =~ "test.haulpage.com"
    end
  end

  describe "handle_info :provisioning_failed" do
    test "clears provisioning state and appends error" do
      socket = chat_socket(%{provisioning?: true, messages: []})

      assert {:noreply, socket} = apply_info(ChatLive, {:provisioning_failed, :timeout}, socket)
      assert socket.assigns.provisioning? == false
      assert length(socket.assigns.messages) == 1
      assert hd(socket.assigns.messages).content =~ "went wrong"
    end
  end

  describe "handle_info :DOWN" do
    test "handles task crash" do
      ref = make_ref()
      socket = chat_socket(%{streaming?: true, task_ref: ref, extraction_ref: nil})

      assert {:noreply, socket} =
               apply_info(ChatLive, {:DOWN, ref, :process, self(), :error}, socket)

      assert socket.assigns.streaming? == false
      assert socket.assigns.task_ref == nil
    end

    test "handles extraction task crash" do
      ref = make_ref()
      socket = chat_socket(%{task_ref: nil, extraction_ref: ref})

      assert {:noreply, socket} =
               apply_info(ChatLive, {:DOWN, ref, :process, self(), :error}, socket)

      assert socket.assigns.extraction_ref == nil
    end

    test "ignores normal exits" do
      ref = make_ref()
      socket = chat_socket(%{streaming?: true, task_ref: ref, extraction_ref: nil})

      assert {:noreply, socket} =
               apply_info(ChatLive, {:DOWN, ref, :process, self(), :normal}, socket)

      # streaming? unchanged because exit was normal
      assert socket.assigns.streaming? == true
    end

    test "ignores unmatched refs" do
      ref = make_ref()
      other_ref = make_ref()
      socket = chat_socket(%{task_ref: other_ref, extraction_ref: nil})

      assert {:noreply, socket} =
               apply_info(ChatLive, {:DOWN, ref, :process, self(), :error}, socket)

      # No change
      assert socket.assigns.task_ref == other_ref
    end
  end
end
