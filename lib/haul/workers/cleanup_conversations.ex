defmodule Haul.Workers.CleanupConversations do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 3

  require Ash.Query
  require Logger

  alias Haul.AI.Conversation

  @stale_days 30

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    cutoff = DateTime.add(DateTime.utc_now(), -@stale_days, :day)

    with :ok <- mark_stale_as_abandoned(cutoff),
         :ok <- delete_old_abandoned(cutoff) do
      :ok
    end
  end

  defp mark_stale_as_abandoned(cutoff) do
    case Conversation
         |> Ash.Query.for_read(:stale_active, %{cutoff: cutoff})
         |> Ash.read() do
      {:ok, conversations} ->
        Enum.each(conversations, fn conv ->
          conv
          |> Ash.Changeset.for_update(:mark_abandoned)
          |> Ash.update()
          |> case do
            {:ok, _} ->
              :ok

            {:error, reason} ->
              Logger.warning("Failed to abandon conversation #{conv.id}: #{inspect(reason)}")
          end
        end)

        :ok

      {:error, reason} ->
        Logger.warning("Failed to query stale conversations: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp delete_old_abandoned(cutoff) do
    case Conversation
         |> Ash.Query.for_read(:old_abandoned, %{cutoff: cutoff})
         |> Ash.read() do
      {:ok, conversations} ->
        count = length(conversations)

        Enum.each(conversations, fn conv ->
          conv
          |> Ash.Changeset.for_destroy(:destroy)
          |> Ash.destroy()
        end)

        if count > 0, do: Logger.info("Cleaned up #{count} abandoned conversations")

        :ok

      {:error, reason} ->
        Logger.warning("Failed to query abandoned conversations: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
