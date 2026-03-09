defmodule Haul.AI.ProfileMapperTest do
  use ExUnit.Case, async: true

  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.AI.ProfileMapper

  @profile %OperatorProfile{
    business_name: "Junk & Handy",
    owner_name: "Mike Johnson",
    phone: "(555) 123-4567",
    email: "mike@junkandhandy.com",
    service_area: "Portland Metro Area",
    tagline: "We haul it all!",
    years_in_business: 8,
    services: [
      %ServiceOffering{
        name: "Junk Removal",
        description: "Full-service removal",
        category: :junk_removal
      },
      %ServiceOffering{name: "Yard Waste", description: nil, category: :yard_waste}
    ],
    differentiators: ["Same-day service"]
  }

  describe "to_company_attrs/1" do
    test "extracts company-relevant fields" do
      attrs = ProfileMapper.to_company_attrs(@profile)
      assert attrs == %{name: "Junk & Handy"}
    end

    test "omits nil fields" do
      profile = %OperatorProfile{business_name: nil}
      attrs = ProfileMapper.to_company_attrs(profile)
      assert attrs == %{}
    end
  end

  describe "to_site_config_attrs/1" do
    test "extracts site config fields" do
      attrs = ProfileMapper.to_site_config_attrs(@profile)

      assert attrs == %{
               business_name: "Junk & Handy",
               owner_name: "Mike Johnson",
               phone: "(555) 123-4567",
               email: "mike@junkandhandy.com",
               service_area: "Portland Metro Area",
               tagline: "We haul it all!"
             }
    end

    test "omits nil optional fields" do
      profile = %OperatorProfile{
        business_name: "Quick Haul",
        phone: "555-0000",
        email: "q@q.com"
      }

      attrs = ProfileMapper.to_site_config_attrs(profile)
      assert attrs == %{business_name: "Quick Haul", phone: "555-0000", email: "q@q.com"}
      refute Map.has_key?(attrs, :tagline)
      refute Map.has_key?(attrs, :service_area)
      refute Map.has_key?(attrs, :owner_name)
    end
  end

  describe "to_service_attrs_list/1" do
    test "converts service offerings to Ash-compatible attrs" do
      services = ProfileMapper.to_service_attrs_list(@profile)

      assert length(services) == 2

      [svc1, svc2] = services
      assert svc1.title == "Junk Removal"
      assert svc1.description == "Full-service removal"
      assert svc1.icon == "fa-truck-ramp-box"
      assert svc1.category == :junk_removal
      assert svc1.sort_order == 0

      assert svc2.title == "Yard Waste"
      assert svc2.description == ""
      assert svc2.icon == "fa-leaf"
      assert svc2.category == :yard_waste
      assert svc2.sort_order == 1
    end

    test "returns empty list for profile with no services" do
      profile = %OperatorProfile{services: []}
      assert ProfileMapper.to_service_attrs_list(profile) == []
    end

    test "assigns fallback icon for unknown category" do
      profile = %OperatorProfile{
        services: [%ServiceOffering{name: "Custom", description: "Desc", category: :other}]
      }

      [svc] = ProfileMapper.to_service_attrs_list(profile)
      assert svc.icon == "fa-hand-holding"
    end
  end

  describe "to_differentiators_content/1" do
    test "converts differentiators to markdown bullet list" do
      content = ProfileMapper.to_differentiators_content(@profile)
      assert content == "- Same-day service"
    end

    test "handles multiple differentiators" do
      profile = %OperatorProfile{
        differentiators: ["Same-day service", "Eco-friendly disposal", "Licensed and insured"]
      }

      content = ProfileMapper.to_differentiators_content(profile)
      assert content == "- Same-day service\n- Eco-friendly disposal\n- Licensed and insured"
    end

    test "returns nil for empty differentiators" do
      profile = %OperatorProfile{differentiators: []}
      assert ProfileMapper.to_differentiators_content(profile) == nil
    end
  end

  describe "missing_fields/1" do
    test "returns empty list when all required fields present" do
      assert ProfileMapper.missing_fields(@profile) == []
    end

    test "lists missing required fields" do
      profile = %OperatorProfile{business_name: "Test"}
      missing = ProfileMapper.missing_fields(profile)

      assert :phone in missing
      assert :email in missing
      refute :business_name in missing
    end

    test "all required fields missing for empty profile" do
      profile = %OperatorProfile{}
      missing = ProfileMapper.missing_fields(profile)

      assert :business_name in missing
      assert :phone in missing
      assert :email in missing
    end
  end
end
