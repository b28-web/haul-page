defmodule Haul.AI.ContentGeneratorTest do
  use ExUnit.Case, async: true

  alias Haul.AI.ContentGenerator
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.AI.Sandbox

  @sample_profile %OperatorProfile{
    business_name: "Junk & Handy",
    owner_name: "Mike Johnson",
    phone: "(555) 123-4567",
    email: "mike@junkandhandy.com",
    service_area: "Portland Metro Area",
    tagline: "We haul it all!",
    years_in_business: 8,
    services: [
      %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal},
      %ServiceOffering{name: "Yard Waste", description: nil, category: :yard_waste},
      %ServiceOffering{name: "Garage Cleanouts", description: nil, category: :cleanouts}
    ],
    differentiators: [
      "Same-day service available",
      "Eco-friendly disposal — we recycle 80%",
      "Licensed and insured"
    ]
  }

  describe "generate_service_descriptions/1" do
    test "returns descriptions for each service" do
      {:ok, descriptions} = ContentGenerator.generate_service_descriptions(@sample_profile)

      assert length(descriptions) == 3
      assert Enum.all?(descriptions, &is_binary(&1.service_name))
      assert Enum.all?(descriptions, &is_binary(&1.description))
      assert Enum.all?(descriptions, &(String.length(&1.description) > 0))
    end

    test "service names match input services" do
      {:ok, descriptions} = ContentGenerator.generate_service_descriptions(@sample_profile)

      names = Enum.map(descriptions, & &1.service_name)
      assert "Junk Removal" in names
      assert "Yard Waste" in names
      assert "Garage Cleanouts" in names
    end

    test "handles error response" do
      Sandbox.set_response("GenerateServiceDescriptions", {:error, :api_error})

      assert {:error, :api_error} =
               ContentGenerator.generate_service_descriptions(@sample_profile)
    end
  end

  describe "generate_taglines/1" do
    test "returns exactly 3 tagline options" do
      {:ok, taglines} = ContentGenerator.generate_taglines(@sample_profile)

      assert length(taglines) == 3
      assert Enum.all?(taglines, &is_binary/1)
      assert Enum.all?(taglines, &(String.length(&1) > 0))
    end

    test "handles error response" do
      Sandbox.set_response("GenerateTagline", {:error, :api_error})

      assert {:error, :api_error} = ContentGenerator.generate_taglines(@sample_profile)
    end
  end

  describe "generate_why_hire_us/1" do
    test "returns exactly 6 bullet points" do
      {:ok, bullets} = ContentGenerator.generate_why_hire_us(@sample_profile)

      assert length(bullets) == 6
      assert Enum.all?(bullets, &is_binary/1)
      assert Enum.all?(bullets, &(String.length(&1) > 0))
    end

    test "handles error response" do
      Sandbox.set_response("GenerateWhyHireUs", {:error, :api_error})

      assert {:error, :api_error} = ContentGenerator.generate_why_hire_us(@sample_profile)
    end
  end

  describe "generate_meta_description/1" do
    test "returns a string within 160 characters" do
      {:ok, meta} = ContentGenerator.generate_meta_description(@sample_profile)

      assert is_binary(meta)
      assert String.length(meta) > 0
      assert String.length(meta) <= 160
    end

    test "truncates descriptions exceeding 160 characters" do
      long_description = String.duplicate("a", 200)

      Sandbox.set_response(
        "GenerateMetaDescription",
        {:ok, %{"description" => long_description}}
      )

      {:ok, meta} = ContentGenerator.generate_meta_description(@sample_profile)

      assert String.length(meta) == 160
      assert String.ends_with?(meta, "...")
    end

    test "handles error response" do
      Sandbox.set_response("GenerateMetaDescription", {:error, :api_error})

      assert {:error, :api_error} = ContentGenerator.generate_meta_description(@sample_profile)
    end
  end

  describe "generate_all/1" do
    test "returns all content types in a single map" do
      {:ok, content} = ContentGenerator.generate_all(@sample_profile)

      assert is_list(content.service_descriptions)
      assert length(content.service_descriptions) == 3
      assert is_list(content.taglines)
      assert length(content.taglines) == 3
      assert is_list(content.why_hire_us)
      assert length(content.why_hire_us) == 6
      assert is_binary(content.meta_description)
      assert String.length(content.meta_description) <= 160
    end

    test "fails fast on first error" do
      Sandbox.set_response("GenerateServiceDescriptions", {:error, :generation_failed})

      assert {:error, :generation_failed} = ContentGenerator.generate_all(@sample_profile)
    end
  end

  describe "with minimal profile" do
    @minimal_profile %OperatorProfile{
      business_name: "Quick Haul",
      phone: "555-0000",
      email: "info@quickhaul.com",
      services: [],
      differentiators: []
    }

    test "generates taglines even with no services" do
      {:ok, taglines} = ContentGenerator.generate_taglines(@minimal_profile)
      assert length(taglines) == 3
    end

    test "generates service descriptions for empty service list" do
      {:ok, descriptions} = ContentGenerator.generate_service_descriptions(@minimal_profile)
      assert descriptions == []
    end

    test "generates meta description with nil service_area" do
      {:ok, meta} = ContentGenerator.generate_meta_description(@minimal_profile)
      assert is_binary(meta)
      assert String.length(meta) > 0
    end
  end

  describe "custom sandbox overrides" do
    test "per-process override works for generation functions" do
      custom_taglines = %{"options" => ["Custom 1", "Custom 2", "Custom 3"]}
      Sandbox.set_response("GenerateTagline", {:ok, custom_taglines})

      {:ok, taglines} = ContentGenerator.generate_taglines(@sample_profile)
      assert taglines == ["Custom 1", "Custom 2", "Custom 3"]
    end
  end
end
