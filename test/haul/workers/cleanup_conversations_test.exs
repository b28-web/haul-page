defmodule Haul.Workers.CleanupConversationsTest do
  use Haul.DataCase, async: true

  alias Haul.AI.Conversation
  alias Haul.Workers.CleanupConversations

  defp create_conversation do
    Conversation
    |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
    |> Ash.create!()
  end

  defp age_conversation(conv, days, field \\ :inserted_at) do
    old_time = DateTime.add(DateTime.utc_now(), -days, :day)
    {:ok, bin_id} = Ecto.UUID.dump(conv.id)

    Ecto.Adapters.SQL.query!(
      Haul.Repo,
      "UPDATE conversations SET #{field} = $1 WHERE id = $2",
      [old_time, bin_id]
    )
  end

  test "marks stale active conversations as abandoned" do
    conv = create_conversation()
    age_conversation(conv, 31)

    assert :ok = CleanupConversations.perform(%Oban.Job{})

    updated =
      Conversation
      |> Ash.Query.for_read(:by_session_id, %{session_id: conv.session_id})
      |> Ash.read_one!()

    assert updated.status == :abandoned
  end

  test "deletes old abandoned conversations" do
    conv = create_conversation()

    conv
    |> Ash.Changeset.for_update(:mark_abandoned)
    |> Ash.update!()

    age_conversation(conv, 31, :updated_at)

    assert :ok = CleanupConversations.perform(%Oban.Job{})

    result =
      Conversation
      |> Ash.Query.for_read(:by_session_id, %{session_id: conv.session_id})
      |> Ash.read_one!()

    assert result == nil
  end

  test "leaves recent active conversations alone" do
    conv = create_conversation()

    assert :ok = CleanupConversations.perform(%Oban.Job{})

    result =
      Conversation
      |> Ash.Query.for_read(:by_session_id, %{session_id: conv.session_id})
      |> Ash.read_one!()

    assert result.status == :active
  end

  test "leaves completed conversations alone" do
    conv = create_conversation()

    conv
    |> Ash.Changeset.for_update(:link_to_company, %{company_id: Ecto.UUID.generate()})
    |> Ash.update!()

    age_conversation(conv, 31)

    assert :ok = CleanupConversations.perform(%Oban.Job{})

    result =
      Conversation
      |> Ash.Query.for_read(:by_session_id, %{session_id: conv.session_id})
      |> Ash.read_one!()

    assert result.status == :completed
  end
end
