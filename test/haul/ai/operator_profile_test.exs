defmodule Haul.AI.OperatorProfileTest do
  use ExUnit.Case, async: true

  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering

  @full_baml_map %{
    "business_name" => "Junk & Handy",
    "owner_name" => "Mike Johnson",
    "phone" => "(555) 123-4567",
    "email" => "mike@junkandhandy.com",
    "service_area" => "Portland Metro Area",
    "tagline" => "We haul it all!",
    "years_in_business" => 8,
    "services" => [
      %{
        "name" => "Junk Removal",
        "description" => "Full-service removal",
        "category" => "JUNK_REMOVAL"
      },
      %{"name" => "Yard Waste", "description" => nil, "category" => "YARD_WASTE"}
    ],
    "differentiators" => ["Same-day service", "Eco-friendly"]
  }

  describe "from_baml/1" do
    test "parses a full profile map into struct" do
      profile = OperatorProfile.from_baml(@full_baml_map)

      assert %OperatorProfile{} = profile
      assert profile.business_name == "Junk & Handy"
      assert profile.owner_name == "Mike Johnson"
      assert profile.phone == "(555) 123-4567"
      assert profile.email == "mike@junkandhandy.com"
      assert profile.service_area == "Portland Metro Area"
      assert profile.tagline == "We haul it all!"
      assert profile.years_in_business == 8
      assert profile.differentiators == ["Same-day service", "Eco-friendly"]
      assert length(profile.services) == 2
    end

    test "parses nested ServiceOffering structs" do
      profile = OperatorProfile.from_baml(@full_baml_map)
      [svc1, svc2] = profile.services

      assert %ServiceOffering{} = svc1
      assert svc1.name == "Junk Removal"
      assert svc1.description == "Full-service removal"
      assert svc1.category == :junk_removal

      assert svc2.name == "Yard Waste"
      assert svc2.description == nil
      assert svc2.category == :yard_waste
    end

    test "handles partial map with missing optional fields" do
      partial = %{
        "business_name" => "Quick Haul",
        "owner_name" => "Jane",
        "phone" => "555-0000",
        "email" => "jane@quickhaul.com",
        "service_area" => "Denver"
      }

      profile = OperatorProfile.from_baml(partial)

      assert profile.business_name == "Quick Haul"
      assert profile.tagline == nil
      assert profile.years_in_business == nil
      assert profile.services == []
      assert profile.differentiators == []
    end

    test "defaults unknown category to :other" do
      map = %{
        "business_name" => "Test",
        "owner_name" => "Test",
        "phone" => "555",
        "email" => "t@t.com",
        "service_area" => "Here",
        "services" => [
          %{
            "name" => "Custom Service",
            "description" => "Something unique",
            "category" => "UNKNOWN_CATEGORY"
          }
        ]
      }

      profile = OperatorProfile.from_baml(map)
      [svc] = profile.services
      assert svc.category == :other
    end

    test "handles nil category" do
      map = %{
        "business_name" => "Test",
        "owner_name" => "Test",
        "phone" => "555",
        "email" => "t@t.com",
        "service_area" => "Here",
        "services" => [
          %{"name" => "No Category", "description" => nil, "category" => nil}
        ]
      }

      profile = OperatorProfile.from_baml(map)
      [svc] = profile.services
      assert svc.category == :other
    end
  end

  describe "service_categories/0" do
    test "returns all valid categories" do
      categories = OperatorProfile.service_categories()
      assert :junk_removal in categories
      assert :cleanouts in categories
      assert :yard_waste in categories
      assert :repairs in categories
      assert :assembly in categories
      assert :moving_help in categories
      assert :other in categories
      assert length(categories) == 7
    end
  end
end
