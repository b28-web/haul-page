defmodule Haul.AI.OperatorProfile do
  @moduledoc """
  Elixir struct mirroring the BAML OperatorProfile type.
  Provides `from_baml/1` to parse BAML string-keyed output into typed structs.
  """

  defstruct [
    :business_name,
    :owner_name,
    :phone,
    :email,
    :service_area,
    :tagline,
    :years_in_business,
    services: [],
    differentiators: []
  ]

  @type t :: %__MODULE__{
          business_name: String.t() | nil,
          owner_name: String.t() | nil,
          phone: String.t() | nil,
          email: String.t() | nil,
          service_area: String.t() | nil,
          tagline: String.t() | nil,
          years_in_business: integer() | nil,
          services: [ServiceOffering.t()],
          differentiators: [String.t()]
        }

  @service_categories ~w(junk_removal cleanouts yard_waste repairs assembly moving_help other)a

  def service_categories, do: @service_categories

  @doc """
  Converts a BAML output map (string keys) into an `OperatorProfile` struct.
  """
  @spec from_baml(map()) :: t()
  def from_baml(map) when is_map(map) do
    %__MODULE__{
      business_name: map["business_name"],
      owner_name: map["owner_name"],
      phone: map["phone"],
      email: map["email"],
      service_area: map["service_area"],
      tagline: map["tagline"],
      years_in_business: map["years_in_business"],
      services: parse_services(map["services"]),
      differentiators: map["differentiators"] || []
    }
  end

  defp parse_services(nil), do: []

  defp parse_services(services) when is_list(services),
    do: Enum.map(services, &__MODULE__.ServiceOffering.from_baml/1)

  defmodule ServiceOffering do
    @moduledoc false

    defstruct [:name, :description, :category]

    @type t :: %__MODULE__{
            name: String.t() | nil,
            description: String.t() | nil,
            category: atom()
          }

    @valid_categories %{
      "JUNK_REMOVAL" => :junk_removal,
      "CLEANOUTS" => :cleanouts,
      "YARD_WASTE" => :yard_waste,
      "REPAIRS" => :repairs,
      "ASSEMBLY" => :assembly,
      "MOVING_HELP" => :moving_help,
      "OTHER" => :other
    }

    @spec from_baml(map()) :: t()
    def from_baml(map) when is_map(map) do
      %__MODULE__{
        name: map["name"],
        description: map["description"],
        category: parse_category(map["category"])
      }
    end

    defp parse_category(nil), do: :other
    defp parse_category(cat) when is_binary(cat), do: Map.get(@valid_categories, cat, :other)
    defp parse_category(cat) when is_atom(cat), do: cat
  end
end
