defmodule Haul.AI.ProfileMapper do
  @moduledoc """
  Converts an `OperatorProfile` struct into attribute maps suitable for Ash resource actions.
  Pure data transformation — no DB access or side effects.
  """

  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering

  @required_fields [:business_name, :phone, :email]

  @category_icons %{
    junk_removal: "fa-truck-ramp-box",
    cleanouts: "fa-broom",
    yard_waste: "fa-leaf",
    repairs: "fa-wrench",
    assembly: "fa-screwdriver",
    moving_help: "fa-dolly",
    other: "fa-hand-holding"
  }

  @doc """
  Extracts Company-relevant attributes from an OperatorProfile.
  """
  @spec to_company_attrs(OperatorProfile.t()) :: map()
  def to_company_attrs(%OperatorProfile{} = profile) do
    %{name: profile.business_name}
    |> reject_nils()
  end

  @doc """
  Extracts SiteConfig-relevant attributes from an OperatorProfile.
  """
  @spec to_site_config_attrs(OperatorProfile.t()) :: map()
  def to_site_config_attrs(%OperatorProfile{} = profile) do
    %{
      business_name: profile.business_name,
      owner_name: profile.owner_name,
      phone: profile.phone,
      email: profile.email,
      service_area: profile.service_area,
      tagline: profile.tagline
    }
    |> reject_nils()
  end

  @doc """
  Converts ServiceOffering list into Service-compatible attribute maps.
  Assigns icons based on category and auto-increments sort_order.
  """
  @spec to_service_attrs_list(OperatorProfile.t()) :: [map()]
  def to_service_attrs_list(%OperatorProfile{services: services}) do
    services
    |> Enum.with_index()
    |> Enum.map(fn {%ServiceOffering{} = svc, idx} ->
      %{
        title: svc.name,
        description: svc.description || "",
        icon: Map.get(@category_icons, svc.category, "fa-hand-holding"),
        category: svc.category,
        sort_order: idx
      }
      |> reject_nils()
    end)
  end

  @doc """
  Converts differentiators list into a markdown bullet-point string.
  Returns nil if the list is empty.
  """
  @spec to_differentiators_content(OperatorProfile.t()) :: String.t() | nil
  def to_differentiators_content(%OperatorProfile{differentiators: []}), do: nil

  def to_differentiators_content(%OperatorProfile{differentiators: items}) do
    items
    |> Enum.map(&"- #{&1}")
    |> Enum.join("\n")
  end

  @doc """
  Returns a list of required fields that are nil in the profile.
  """
  @spec missing_fields(OperatorProfile.t()) :: [atom()]
  def missing_fields(%OperatorProfile{} = profile) do
    Enum.filter(@required_fields, fn field ->
      is_nil(Map.get(profile, field))
    end)
  end

  defp reject_nils(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
