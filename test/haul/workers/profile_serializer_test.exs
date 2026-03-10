defmodule Haul.Workers.ProfileSerializerTest do
  use ExUnit.Case, async: true

  alias Haul.AI.OperatorProfile
  alias Haul.Workers.ProfileSerializer

  @profile %OperatorProfile{
    business_name: "Test Hauling",
    owner_name: "Jane Doe",
    phone: "555-1234",
    email: "jane@test.com",
    service_area: "Portland, OR",
    tagline: "We haul it all!",
    years_in_business: 5,
    services: [
      %OperatorProfile.ServiceOffering{
        name: "Junk Removal",
        description: "Full service junk removal",
        category: :junk_removal
      },
      %OperatorProfile.ServiceOffering{
        name: "Yard Waste",
        description: "Yard debris hauling",
        category: :yard_waste
      }
    ],
    differentiators: ["Same-day service", "Eco-friendly"]
  }

  describe "serialize/1" do
    test "converts profile struct to string-keyed map" do
      result = ProfileSerializer.serialize(@profile)

      assert result["business_name"] == "Test Hauling"
      assert result["owner_name"] == "Jane Doe"
      assert result["phone"] == "555-1234"
      assert result["email"] == "jane@test.com"
      assert result["service_area"] == "Portland, OR"
      assert result["tagline"] == "We haul it all!"
      assert result["years_in_business"] == 5
      assert result["differentiators"] == ["Same-day service", "Eco-friendly"]
    end

    test "converts services to string-keyed maps with string categories" do
      result = ProfileSerializer.serialize(@profile)
      services = result["services"]

      assert length(services) == 2
      first = hd(services)
      assert first["name"] == "Junk Removal"
      assert first["description"] == "Full service junk removal"
      assert first["category"] == "junk_removal"
    end

    test "handles empty services list" do
      profile = %OperatorProfile{business_name: "Test", services: []}
      result = ProfileSerializer.serialize(profile)
      assert result["services"] == []
    end

    test "handles nil fields" do
      profile = %OperatorProfile{}
      result = ProfileSerializer.serialize(profile)
      assert result["business_name"] == nil
      assert result["phone"] == nil
    end
  end

  describe "deserialize/1" do
    test "reconstructs profile from serialized map" do
      serialized = ProfileSerializer.serialize(@profile)
      result = ProfileSerializer.deserialize(serialized)

      assert %OperatorProfile{} = result
      assert result.business_name == "Test Hauling"
      assert result.owner_name == "Jane Doe"
      assert result.phone == "555-1234"
      assert result.email == "jane@test.com"
      assert result.service_area == "Portland, OR"
      assert result.tagline == "We haul it all!"
      assert result.years_in_business == 5
      assert result.differentiators == ["Same-day service", "Eco-friendly"]
    end

    test "reconstructs services with atom categories" do
      serialized = ProfileSerializer.serialize(@profile)
      result = ProfileSerializer.deserialize(serialized)

      assert length(result.services) == 2
      first = hd(result.services)
      assert %OperatorProfile.ServiceOffering{} = first
      assert first.name == "Junk Removal"
      assert first.category == :junk_removal
    end

    test "handles missing services key" do
      result = ProfileSerializer.deserialize(%{"business_name" => "Test"})
      assert result.services == []
    end

    test "handles missing differentiators key" do
      result = ProfileSerializer.deserialize(%{"business_name" => "Test"})
      assert result.differentiators == []
    end

    test "round-trips profile correctly" do
      result = @profile |> ProfileSerializer.serialize() |> ProfileSerializer.deserialize()
      assert result.business_name == @profile.business_name
      assert result.owner_name == @profile.owner_name
      assert result.phone == @profile.phone
      assert result.email == @profile.email
      assert result.service_area == @profile.service_area
      assert result.tagline == @profile.tagline
      assert result.years_in_business == @profile.years_in_business
      assert length(result.services) == length(@profile.services)
      assert result.differentiators == @profile.differentiators
    end
  end

  describe "safe_atom/1" do
    test "returns :other for nil" do
      assert ProfileSerializer.safe_atom(nil) == :other
    end

    test "passes through atoms" do
      assert ProfileSerializer.safe_atom(:junk_removal) == :junk_removal
    end

    test "converts known string to atom" do
      assert ProfileSerializer.safe_atom("junk_removal") == :junk_removal
    end

    test "returns :other for unknown string" do
      assert ProfileSerializer.safe_atom("completely_unknown_atom_xyz_123") == :other
    end
  end
end
