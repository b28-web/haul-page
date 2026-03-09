defmodule Haul.AI.ChatTest do
  use ExUnit.Case, async: false

  alias Haul.AI.Chat
  alias Haul.AI.Chat.Sandbox

  setup do
    Sandbox.clear_response()
    Sandbox.clear_error()
    :ok
  end

  describe "Sandbox adapter" do
    test "send_message/2 returns default response" do
      assert {:ok, response} = Sandbox.send_message([], "system prompt")
      assert is_binary(response)
      assert String.length(response) > 0
    end

    test "set_response/1 overrides response" do
      Sandbox.set_response("Custom reply!")
      assert {:ok, "Custom reply!"} = Sandbox.send_message([], "system prompt")
    end

    test "stream_message/3 sends chunks then done" do
      Sandbox.set_response("Hello!")
      assert :ok = Sandbox.stream_message([], "system prompt", self())

      # Collect all chunks
      chunks = collect_chunks()
      assert Enum.join(chunks) == "Hello!"
    end

    test "stream_message/3 sends :ai_done after all chunks" do
      Sandbox.set_response("Hi")
      Sandbox.stream_message([], "system prompt", self())

      # Wait for done
      assert_receive {:ai_done}, 1000
    end
  end

  describe "Chat module dispatch" do
    test "send_message/2 delegates to configured adapter" do
      assert {:ok, response} = Chat.send_message([], "system prompt")
      assert is_binary(response)
    end

    test "stream_message/3 delegates to configured adapter" do
      assert :ok = Chat.stream_message([], "system prompt", self())
      assert_receive {:ai_done}, 1000
    end
  end

  defp collect_chunks(acc \\ []) do
    receive do
      {:ai_chunk, text} -> collect_chunks(acc ++ [text])
      {:ai_done} -> acc
    after
      1000 -> acc
    end
  end
end
