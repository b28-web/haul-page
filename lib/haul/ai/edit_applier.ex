defmodule Haul.AI.EditApplier do
  @moduledoc """
  Applies classified edit instructions to tenant content resources.
  Handles direct updates, service management, and LLM-assisted regeneration.
  """

  alias Haul.AI.ContentGenerator
  alias Haul.AI.OperatorProfile
  alias Haul.Content.{Service, SiteConfig}

  require Logger

  @site_config_fields [:phone, :email, :business_name, :owner_name, :service_area]

  @doc """
  Applies an edit instruction to the tenant's content.
  Returns `{:ok, confirmation_message}` or `{:error, error_message}`.
  """
  @spec apply_edit(
          Haul.AI.EditClassifier.edit_instruction(),
          String.t(),
          OperatorProfile.t()
        ) :: {:ok, String.t()} | {:error, String.t()}
  def apply_edit({:direct, field, value}, tenant, _profile) when field in @site_config_fields do
    case update_site_config(tenant, %{field => value}) do
      :ok ->
        label = field |> to_string() |> String.replace("_", " ")
        {:ok, "Updated #{label} to \"#{value}\"."}

      {:error, reason} ->
        Logger.error("[EditApplier] Failed to update #{field}: #{inspect(reason)}")
        {:error, "Failed to update #{field}. Please try again."}
    end
  end

  def apply_edit({:regenerate, :tagline, _hint}, tenant, profile) do
    case ContentGenerator.generate_taglines(profile) do
      {:ok, [tagline | _]} ->
        case update_site_config(tenant, %{tagline: tagline}) do
          :ok -> {:ok, "Updated tagline to: \"#{tagline}\""}
          {:error, _} -> {:error, "Generated a new tagline but failed to save it."}
        end

      {:error, reason} ->
        Logger.error("[EditApplier] Tagline generation failed: #{inspect(reason)}")
        {:error, "Failed to generate a new tagline. Please try again."}
    end
  end

  def apply_edit({:regenerate, :descriptions, _hint}, tenant, profile) do
    case ContentGenerator.generate_service_descriptions(profile) do
      {:ok, descriptions} ->
        update_service_descriptions(tenant, descriptions)
        {:ok, "Updated service descriptions."}

      {:error, reason} ->
        Logger.error("[EditApplier] Description generation failed: #{inspect(reason)}")
        {:error, "Failed to regenerate descriptions. Please try again."}
    end
  end

  def apply_edit({:remove_service, name}, tenant, _profile) do
    services = Ash.read!(Service, tenant: tenant)
    match = Enum.find(services, fn s -> String.downcase(s.title) == String.downcase(name) end)

    case match do
      nil ->
        {:error, "Could not find a service called \"#{name}\"."}

      service ->
        case service
             |> Ash.Changeset.for_update(:edit, %{active: false})
             |> Ash.update() do
          {:ok, _} ->
            {:ok, "Removed \"#{service.title}\" service."}

          {:error, reason} ->
            Logger.error("[EditApplier] Failed to remove service: #{inspect(reason)}")
            {:error, "Failed to remove \"#{name}\". Please try again."}
        end
    end
  end

  def apply_edit({:add_service, name}, tenant, _profile) do
    attrs = %{
      title: name,
      description: "Professional #{String.downcase(name)} services.",
      icon: "fa-hand-holding",
      sort_order: 99
    }

    case Service
         |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
         |> Ash.create() do
      {:ok, _} ->
        {:ok, "Added \"#{name}\" service."}

      {:error, reason} ->
        Logger.error("[EditApplier] Failed to add service: #{inspect(reason)}")
        {:error, "Failed to add \"#{name}\". Please try again."}
    end
  end

  def apply_edit({:unknown, _message}, _tenant, _profile) do
    {:error,
     "I'm not sure what to change. Try something like:\n" <>
       "- \"Change phone to 555-1234\"\n" <>
       "- \"Update the tagline\"\n" <>
       "- \"Remove the Assembly service\""}
  end

  defp update_site_config(tenant, attrs) do
    case Ash.read!(SiteConfig, tenant: tenant) do
      [config] ->
        case config
             |> Ash.Changeset.for_update(:edit, attrs)
             |> Ash.update() do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end

      [] ->
        {:error, :no_site_config}
    end
  end

  defp update_service_descriptions(tenant, descriptions) do
    desc_map = Map.new(descriptions, fn %{service_name: n, description: d} -> {n, d} end)
    services = Ash.read!(Service, tenant: tenant)

    Enum.each(services, fn svc ->
      case Map.get(desc_map, svc.title) do
        nil ->
          :ok

        desc ->
          svc
          |> Ash.Changeset.for_update(:edit, %{description: desc})
          |> Ash.update()
      end
    end)
  end
end
