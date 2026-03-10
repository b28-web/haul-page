defmodule Haul.Workers.ProfileSerializer do
  @moduledoc """
  Serializes and deserializes OperatorProfile structs for Oban job args.

  Extracted from ProvisionSite worker to enable isolated testing.
  """

  alias Haul.AI.OperatorProfile

  @doc """
  Converts an OperatorProfile struct to a plain map with string keys,
  suitable for JSON serialization in Oban job args.
  """
  @spec serialize(OperatorProfile.t()) :: map()
  def serialize(%OperatorProfile{} = profile) do
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

  @doc """
  Reconstructs an OperatorProfile struct from a plain map with string keys.
  """
  @spec deserialize(map()) :: OperatorProfile.t()
  def deserialize(map) when is_map(map) do
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

  @doc """
  Safely converts a string to an existing atom, falling back to `:other`.
  """
  @spec safe_atom(term()) :: atom()
  def safe_atom(nil), do: :other
  def safe_atom(val) when is_atom(val), do: val

  def safe_atom(val) when is_binary(val) do
    String.to_existing_atom(val)
  rescue
    ArgumentError -> :other
  end
end
