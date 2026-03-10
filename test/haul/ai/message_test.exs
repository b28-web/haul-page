defmodule Haul.AI.MessageTest do
  use ExUnit.Case, async: true

  alias Haul.AI.Message

  describe "build_transcript/1" do
    test "builds transcript from messages" do
      messages = [
        %{role: :user, content: "Hello"},
        %{role: :assistant, content: "Hi there"},
        %{role: :user, content: "Help me"}
      ]

      assert Message.build_transcript(messages) ==
               "user: Hello\nassistant: Hi there\nuser: Help me"
    end

    test "skips empty content" do
      messages = [
        %{role: :user, content: "Hello"},
        %{role: :assistant, content: ""}
      ]

      assert Message.build_transcript(messages) == "user: Hello"
    end

    test "empty list returns empty string" do
      assert Message.build_transcript([]) == ""
    end
  end

  describe "append_to_last_assistant/2" do
    test "appends to last assistant message" do
      messages = [
        %{role: :user, content: "Hi"},
        %{role: :assistant, content: "Hello"}
      ]

      result = Message.append_to_last_assistant(messages, " world")
      assert List.last(result).content == "Hello world"
    end

    test "returns unchanged if last is not assistant" do
      messages = [%{role: :user, content: "Hi"}]
      assert Message.append_to_last_assistant(messages, " extra") == messages
    end

    test "returns empty list unchanged" do
      assert Message.append_to_last_assistant([], "text") == []
    end
  end

  describe "has_assistant_content?/1" do
    test "true when last is non-empty assistant" do
      messages = [%{role: :assistant, content: "Hello"}]
      assert Message.has_assistant_content?(messages) == true
    end

    test "false when last is empty assistant" do
      messages = [%{role: :assistant, content: ""}]
      assert Message.has_assistant_content?(messages) == false
    end

    test "false when last is user" do
      messages = [%{role: :user, content: "Hi"}]
      assert Message.has_assistant_content?(messages) == false
    end

    test "false for empty list" do
      assert Message.has_assistant_content?([]) == false
    end
  end

  describe "deep_to_map/1" do
    test "converts struct to map" do
      struct = %URI{host: "example.com", port: 443}
      result = Message.deep_to_map(struct)
      assert is_map(result)
      refute Map.has_key?(result, :__struct__)
      assert result.host == "example.com"
    end

    test "converts nested structs" do
      inner = %URI{host: "inner.com"}
      outer = %{__struct__: MyStruct, child: inner, name: "test"}
      result = Message.deep_to_map(outer)
      assert result.child.host == "inner.com"
      refute Map.has_key?(result.child, :__struct__)
    end

    test "converts list of structs" do
      list = [%URI{host: "a.com"}, %URI{host: "b.com"}]
      result = Message.deep_to_map(list)
      assert length(result) == 2
      assert Enum.all?(result, &is_map/1)
    end

    test "passes through plain values" do
      assert Message.deep_to_map("hello") == "hello"
      assert Message.deep_to_map(42) == 42
      assert Message.deep_to_map(nil) == nil
    end
  end

  describe "restore_messages/1" do
    test "converts DB format to runtime format" do
      db_msgs = [
        %{"role" => "user", "content" => "Hi"},
        %{"role" => "assistant", "content" => "Hello"}
      ]

      result = Message.restore_messages(db_msgs)
      assert length(result) == 2
      assert Enum.at(result, 0).role == :user
      assert Enum.at(result, 0).content == "Hi"
      assert Enum.at(result, 1).role == :assistant
      assert is_binary(Enum.at(result, 0).id)
    end

    test "handles nil content" do
      db_msgs = [%{"role" => "user", "content" => nil}]
      [msg] = Message.restore_messages(db_msgs)
      assert msg.content == ""
    end

    test "returns empty list for nil" do
      assert Message.restore_messages(nil) == []
    end

    test "returns empty list for non-list" do
      assert Message.restore_messages("invalid") == []
    end
  end
end
