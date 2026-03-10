defmodule Haul.Workers.ProvisionSite do
  @moduledoc """
  Oban worker that runs the full provisioning pipeline for a new operator.

  Enqueued from ChatLive when an operator's profile is complete.
  Broadcasts results via PubSub so ChatLive can update the UI.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias Haul.AI.OperatorProfile
  alias Haul.AI.Provisioner
  alias Haul.Workers.ProfileSerializer

  require Logger

  @doc """
  Enqueues a provisioning job.
  """
  def enqueue(conversation_id, %OperatorProfile{} = profile, session_id) do
    %{
      "conversation_id" => conversation_id,
      "session_id" => session_id,
      "profile" => ProfileSerializer.serialize(profile)
    }
    |> new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "conversation_id" => conv_id,
          "session_id" => session_id,
          "profile" => profile_map
        }
      }) do
    profile = ProfileSerializer.deserialize(profile_map)

    case Provisioner.from_profile(profile, conv_id) do
      {:ok, result} ->
        broadcast(
          session_id,
          {:provisioning_complete,
           %{
             site_url: result.site_url,
             company_name: result.company.name,
             tenant: result.tenant,
             company: result.company,
             duration_ms: result.duration_ms
           }}
        )

        :ok

      {:error, step, reason} ->
        Logger.error("[ProvisionSite] Failed at #{step}: #{inspect(reason)}")

        broadcast(
          session_id,
          {:provisioning_failed,
           %{
             step: step,
             reason: inspect(reason)
           }}
        )

        {:error, "#{step}: #{inspect(reason)}"}
    end
  end

  defp broadcast(session_id, message) do
    Phoenix.PubSub.broadcast(
      Haul.PubSub,
      "provisioning:#{session_id}",
      message
    )
  end
end
