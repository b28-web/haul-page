defmodule Haul.Workers.ProvisionSite do
  @moduledoc """
  Oban worker that runs the full provisioning pipeline for a new operator.

  Enqueued from ChatLive when an operator's profile is complete.
  Broadcasts results via PubSub so ChatLive can update the UI.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias Haul.AI.OperatorProfile
  alias Haul.AI.Provisioner

  require Logger

  @doc """
  Enqueues a provisioning job.
  """
  def enqueue(conversation_id, %OperatorProfile{} = profile, session_id) do
    %{
      "conversation_id" => conversation_id,
      "session_id" => session_id,
      "profile" => serialize_profile(profile)
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
    profile = deserialize_profile(profile_map)

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

  defp serialize_profile(%OperatorProfile{} = profile) do
    %{
      "business_name" => profile.business_name,
      "owner_name" => profile.owner_name,
      "phone" => profile.phone,
      "email" => profile.email,
      "service_area" => profile.service_area,
      "tagline" => profile.tagline,
      "years_in_business" => profile.years_in_business,
      "services" =>
        Enum.map(profile.services, fn svc ->
          %{
            "name" => svc.name,
            "description" => svc.description,
            "category" => to_string(svc.category)
          }
        end),
      "differentiators" => profile.differentiators
    }
  end

  defp deserialize_profile(map) do
    %OperatorProfile{
      business_name: map["business_name"],
      owner_name: map["owner_name"],
      phone: map["phone"],
      email: map["email"],
      service_area: map["service_area"],
      tagline: map["tagline"],
      years_in_business: map["years_in_business"],
      services:
        Enum.map(map["services"] || [], fn svc ->
          %OperatorProfile.ServiceOffering{
            name: svc["name"],
            description: svc["description"],
            category: safe_atom(svc["category"])
          }
        end),
      differentiators: map["differentiators"] || []
    }
  end

  defp safe_atom(nil), do: :other
  defp safe_atom(val) when is_atom(val), do: val

  defp safe_atom(val) when is_binary(val) do
    String.to_existing_atom(val)
  rescue
    ArgumentError -> :other
  end
end
