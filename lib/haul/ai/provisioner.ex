defmodule Haul.AI.Provisioner do
  @moduledoc """
  Orchestrates the full provisioning pipeline: validate profile → generate content →
  create tenant → seed content → apply generated content → link conversation.

  Each step is idempotent. Safe to retry on partial failure.
  """

  alias Haul.AI.ContentGenerator
  alias Haul.AI.Conversation
  alias Haul.AI.OperatorProfile
  alias Haul.AI.ProfileMapper
  alias Haul.Content.{Service, SiteConfig}

  require Logger

  @type result :: %{
          company: Haul.Accounts.Company.t(),
          site_url: String.t(),
          tenant: String.t(),
          generated_content: map(),
          duration_ms: integer()
        }

  @doc """
  Runs the full provisioning pipeline from an extracted operator profile.

  Returns `{:ok, result}` on success or `{:error, step, reason}` on failure.
  """
  @spec from_profile(OperatorProfile.t(), String.t()) ::
          {:ok, result()} | {:error, atom(), term()}
  def from_profile(%OperatorProfile{} = profile, conversation_id) do
    start = System.monotonic_time(:millisecond)

    with :ok <- validate_profile(profile),
         {:ok, conversation} <- load_conversation(conversation_id),
         {:ok, _} <- mark_provisioning(conversation),
         {:ok, generated} <- generate_content(profile),
         {:ok, onboard_result} <- onboard_from_profile(profile),
         :ok <- apply_generated_content(onboard_result.tenant, profile, generated),
         {:ok, _} <- link_conversation(conversation, onboard_result.company.id) do
      duration = System.monotonic_time(:millisecond) - start

      Logger.info("[Provisioner] Pipeline complete for #{profile.business_name} in #{duration}ms")

      {:ok,
       %{
         company: onboard_result.company,
         site_url: Haul.Onboarding.site_url(onboard_result.company.slug),
         tenant: onboard_result.tenant,
         generated_content: generated,
         duration_ms: duration
       }}
    else
      {:error, step, reason} = error ->
        Logger.error("[Provisioner] Failed at #{step}: #{inspect(reason)}")

        # Try to mark conversation as failed (best-effort)
        with {:ok, conv} <- load_conversation(conversation_id) do
          mark_failed(conv)
        end

        error
    end
  end

  defp validate_profile(%OperatorProfile{} = profile) do
    missing = ProfileMapper.missing_fields(profile)

    if missing == [] do
      :ok
    else
      {:error, :validation, {:missing_fields, missing}}
    end
  end

  defp load_conversation(conversation_id) do
    case Conversation
         |> Ash.get(conversation_id) do
      {:ok, conv} -> {:ok, conv}
      {:error, reason} -> {:error, :conversation_load, reason}
    end
  end

  defp mark_provisioning(conversation) do
    conversation
    |> Ash.Changeset.for_update(:mark_provisioning, %{})
    |> Ash.update()
    |> case do
      {:ok, _} = ok -> ok
      {:error, reason} -> {:error, :mark_provisioning, reason}
    end
  end

  defp mark_failed(conversation) do
    conversation
    |> Ash.Changeset.for_update(:mark_failed, %{})
    |> Ash.update()
  end

  defp generate_content(%OperatorProfile{} = profile) do
    case ContentGenerator.generate_all(profile) do
      {:ok, _} = ok -> ok
      {:error, reason} -> {:error, :content_generation, reason}
    end
  end

  defp onboard_from_profile(%OperatorProfile{} = profile) do
    params = %{
      name: profile.business_name,
      phone: profile.phone,
      email: profile.email,
      area: profile.service_area || ""
    }

    case Haul.Onboarding.run(params) do
      {:ok, _} = ok -> ok
      {:error, step, reason} -> {:error, step, reason}
    end
  end

  defp apply_generated_content(tenant, profile, generated) do
    with :ok <- update_site_config(tenant, profile, generated),
         :ok <- update_services(tenant, profile, generated) do
      :ok
    end
  end

  defp update_site_config(tenant, profile, generated) do
    attrs =
      ProfileMapper.to_site_config_attrs(profile)
      |> Map.put(:meta_description, generated.meta_description)
      |> maybe_put_tagline(generated)

    case Ash.read!(SiteConfig, tenant: tenant) do
      [config] ->
        case config
             |> Ash.Changeset.for_update(:edit, attrs)
             |> Ash.update() do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, :site_config_update, reason}
        end

      [] ->
        :ok
    end
  end

  defp maybe_put_tagline(attrs, %{taglines: [first | _]}), do: Map.put(attrs, :tagline, first)
  defp maybe_put_tagline(attrs, _), do: attrs

  defp update_services(tenant, _profile, generated) do
    desc_map =
      generated.service_descriptions
      |> Enum.into(%{}, fn %{service_name: name, description: desc} -> {name, desc} end)

    existing_services = Ash.read!(Service, tenant: tenant)

    Enum.each(existing_services, fn svc ->
      case Map.get(desc_map, svc.title) do
        nil ->
          :ok

        description ->
          svc
          |> Ash.Changeset.for_update(:edit, %{description: description})
          |> Ash.update()
      end
    end)

    # Create services from profile that don't exist yet
    existing_titles = MapSet.new(existing_services, & &1.title)

    profile_services =
      ProfileMapper.to_service_attrs_list(%OperatorProfile{
        services:
          generated.service_descriptions
          |> Enum.map(fn %{service_name: name, description: desc} ->
            %OperatorProfile.ServiceOffering{name: name, description: desc, category: :other}
          end)
      })

    Enum.each(profile_services, fn attrs ->
      unless MapSet.member?(existing_titles, attrs.title) do
        Service
        |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
        |> Ash.create()
      end
    end)

    :ok
  end

  defp link_conversation(conversation, company_id) do
    conversation
    |> Ash.Changeset.for_update(:link_to_company, %{company_id: company_id})
    |> Ash.update()
    |> case do
      {:ok, _} = ok -> ok
      {:error, reason} -> {:error, :link_conversation, reason}
    end
  end
end
