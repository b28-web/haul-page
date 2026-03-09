defmodule Haul.AI.ConversationTest do
  use Haul.DataCase, async: true

  alias Haul.AI.Conversation

  defp uuid_to_bin(uuid) do
    {:ok, bin} = Ecto.UUID.dump(uuid)
    bin
  end

  defp create_conversation(attrs \\ %{}) do
    session_id = attrs[:session_id] || Ecto.UUID.generate()

    Conversation
    |> Ash.Changeset.for_create(:start, %{session_id: session_id})
    |> Ash.create!()
  end

  describe "start action" do
    test "creates a conversation with session_id" do
      session_id = Ecto.UUID.generate()

      conv =
        Conversation
        |> Ash.Changeset.for_create(:start, %{session_id: session_id})
        |> Ash.create!()

      assert conv.session_id == session_id
      assert conv.messages == []
      assert conv.status == :active
      assert conv.company_id == nil
      assert conv.extracted_profile == nil
    end

    test "rejects duplicate session_id" do
      session_id = Ecto.UUID.generate()
      create_conversation(session_id: session_id)

      assert {:error, _} =
               Conversation
               |> Ash.Changeset.for_create(:start, %{session_id: session_id})
               |> Ash.create()
    end
  end

  describe "by_session_id action" do
    test "finds conversation by session_id" do
      conv = create_conversation()

      found =
        Conversation
        |> Ash.Query.for_read(:by_session_id, %{session_id: conv.session_id})
        |> Ash.read_one!()

      assert found.id == conv.id
    end

    test "returns nil for unknown session_id" do
      result =
        Conversation
        |> Ash.Query.for_read(:by_session_id, %{session_id: Ecto.UUID.generate()})
        |> Ash.read_one!()

      assert result == nil
    end
  end

  describe "add_message action" do
    test "appends message to conversation" do
      conv = create_conversation()

      updated =
        conv
        |> Ash.Changeset.for_update(:add_message, %{
          message: %{"role" => "user", "content" => "Hello"}
        })
        |> Ash.update!()

      assert length(updated.messages) == 1
      [msg] = updated.messages
      assert msg["role"] == "user"
      assert msg["content"] == "Hello"
      assert msg["timestamp"]
    end

    test "preserves message order with multiple messages" do
      conv = create_conversation()

      conv =
        conv
        |> Ash.Changeset.for_update(:add_message, %{
          message: %{"role" => "user", "content" => "First"}
        })
        |> Ash.update!()

      conv =
        conv
        |> Ash.Changeset.for_update(:add_message, %{
          message: %{"role" => "assistant", "content" => "Second"}
        })
        |> Ash.update!()

      conv =
        conv
        |> Ash.Changeset.for_update(:add_message, %{
          message: %{"role" => "user", "content" => "Third"}
        })
        |> Ash.update!()

      assert length(conv.messages) == 3
      assert Enum.map(conv.messages, & &1["content"]) == ["First", "Second", "Third"]
      assert Enum.map(conv.messages, & &1["role"]) == ["user", "assistant", "user"]
    end

    test "handles atom keys in message" do
      conv = create_conversation()

      updated =
        conv
        |> Ash.Changeset.for_update(:add_message, %{
          message: %{role: "user", content: "Hello"}
        })
        |> Ash.update!()

      [msg] = updated.messages
      assert msg["role"] == "user"
      assert msg["content"] == "Hello"
    end
  end

  describe "save_profile action" do
    test "stores extracted profile" do
      conv = create_conversation()
      profile = %{"business_name" => "Test Co", "phone" => "555-1234"}

      updated =
        conv
        |> Ash.Changeset.for_update(:save_profile, %{extracted_profile: profile})
        |> Ash.update!()

      assert updated.extracted_profile == profile
    end
  end

  describe "link_to_company action" do
    test "sets company_id and marks as completed" do
      conv = create_conversation()
      company_id = Ecto.UUID.generate()

      updated =
        conv
        |> Ash.Changeset.for_update(:link_to_company, %{company_id: company_id})
        |> Ash.update!()

      assert updated.company_id == company_id
      assert updated.status == :completed
    end
  end

  describe "mark_abandoned action" do
    test "sets status to abandoned" do
      conv = create_conversation()

      updated =
        conv
        |> Ash.Changeset.for_update(:mark_abandoned)
        |> Ash.update!()

      assert updated.status == :abandoned
    end
  end

  describe "stale_active action" do
    test "returns active conversations older than cutoff" do
      conv = create_conversation()

      # Set inserted_at to 31 days ago via raw SQL
      Ecto.Adapters.SQL.query!(
        Haul.Repo,
        "UPDATE conversations SET inserted_at = $1 WHERE id = $2",
        [DateTime.add(DateTime.utc_now(), -31, :day), uuid_to_bin(conv.id)]
      )

      cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

      results =
        Conversation
        |> Ash.Query.for_read(:stale_active, %{cutoff: cutoff})
        |> Ash.read!()

      assert length(results) == 1
      assert hd(results).id == conv.id
    end

    test "excludes recent conversations" do
      _conv = create_conversation()
      cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

      results =
        Conversation
        |> Ash.Query.for_read(:stale_active, %{cutoff: cutoff})
        |> Ash.read!()

      assert results == []
    end

    test "excludes completed conversations" do
      conv = create_conversation()

      conv
      |> Ash.Changeset.for_update(:link_to_company, %{company_id: Ecto.UUID.generate()})
      |> Ash.update!()

      Ecto.Adapters.SQL.query!(
        Haul.Repo,
        "UPDATE conversations SET inserted_at = $1 WHERE id = $2",
        [DateTime.add(DateTime.utc_now(), -31, :day), uuid_to_bin(conv.id)]
      )

      cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

      results =
        Conversation
        |> Ash.Query.for_read(:stale_active, %{cutoff: cutoff})
        |> Ash.read!()

      assert results == []
    end
  end

  describe "old_abandoned action" do
    test "returns abandoned conversations older than cutoff" do
      conv = create_conversation()

      conv
      |> Ash.Changeset.for_update(:mark_abandoned)
      |> Ash.update!()

      Ecto.Adapters.SQL.query!(
        Haul.Repo,
        "UPDATE conversations SET updated_at = $1 WHERE id = $2",
        [DateTime.add(DateTime.utc_now(), -31, :day), uuid_to_bin(conv.id)]
      )

      cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

      results =
        Conversation
        |> Ash.Query.for_read(:old_abandoned, %{cutoff: cutoff})
        |> Ash.read!()

      assert length(results) == 1
    end
  end

  describe "destroy action" do
    test "deletes conversation" do
      conv = create_conversation()

      conv
      |> Ash.Changeset.for_destroy(:destroy)
      |> Ash.destroy!()

      assert nil ==
               Conversation
               |> Ash.Query.for_read(:by_session_id, %{session_id: conv.session_id})
               |> Ash.read_one!()
    end
  end
end
