defmodule Haul.AI.ProvisionerTest do
  use Haul.DataCase, async: false

  alias Haul.AI.Conversation
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.AI.Provisioner
  alias Haul.Content.{Service, SiteConfig}

  setup do
    unique = System.unique_integer([:positive])
    biz_name = "Provision Test Co #{unique}"

    slug =
      biz_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    tenant = "tenant_#{slug}"

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant}" CASCADE))
    end)

    # Create a conversation
    {:ok, conversation} =
      Conversation
      |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
      |> Ash.create()

    profile = %OperatorProfile{
      business_name: biz_name,
      owner_name: "Test Owner",
      phone: "555-9999",
      email: "provision-#{unique}@example.com",
      service_area: "Test City, TC",
      tagline: "We test it all!",
      years_in_business: 5,
      services: [
        %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal},
        %ServiceOffering{name: "Yard Waste", description: nil, category: :yard_waste}
      ],
      differentiators: ["Fast", "Reliable"]
    }

    %{conversation: conversation, profile: profile, slug: slug, tenant: tenant}
  end

  describe "from_profile/2" do
    test "completes full pipeline successfully", %{
      conversation: conv,
      profile: profile,
      slug: slug,
      tenant: tenant
    } do
      assert {:ok, result} = Provisioner.from_profile(profile, conv.id)

      assert result.company.name == profile.business_name
      assert result.site_url =~ slug
      assert result.tenant == tenant
      assert is_integer(result.duration_ms)
      assert result.duration_ms >= 0

      # Generated content is present
      assert is_map(result.generated_content)
      assert is_list(result.generated_content.service_descriptions)
      assert is_list(result.generated_content.taglines)
      assert is_list(result.generated_content.why_hire_us)
      assert is_binary(result.generated_content.meta_description)
    end

    test "conversation is linked to company on success", %{conversation: conv, profile: profile} do
      assert {:ok, result} = Provisioner.from_profile(profile, conv.id)

      # Reload conversation
      {:ok, updated} = Ash.get(Conversation, conv.id)
      assert updated.status == :completed
      assert updated.company_id == result.company.id
    end

    test "site config is updated with generated content", %{conversation: conv, profile: profile} do
      assert {:ok, result} = Provisioner.from_profile(profile, conv.id)

      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.business_name == profile.business_name
      assert config.phone == "555-9999"
      assert config.email == profile.email
      assert config.service_area == "Test City, TC"
      # Generated meta description should be set
      assert is_binary(config.meta_description)
      assert String.length(config.meta_description) > 0
      # Generated tagline should be set
      assert is_binary(config.tagline)
    end

    test "services have generated descriptions", %{conversation: conv, profile: profile} do
      assert {:ok, result} = Provisioner.from_profile(profile, conv.id)

      services = Ash.read!(Service, tenant: result.tenant)
      assert length(services) > 0

      # At least some services should have descriptions
      described = Enum.filter(services, &(String.length(&1.description) > 0))
      assert length(described) > 0
    end

    test "rejects profile with missing required fields", %{conversation: conv} do
      incomplete = %OperatorProfile{
        business_name: "Test",
        services: [],
        differentiators: []
      }

      assert {:error, :validation, {:missing_fields, missing}} =
               Provisioner.from_profile(incomplete, conv.id)

      assert :phone in missing
      assert :email in missing
    end

    test "marks conversation as failed on error", %{conversation: conv} do
      incomplete = %OperatorProfile{
        business_name: "Test",
        services: [],
        differentiators: []
      }

      assert {:error, :validation, _} = Provisioner.from_profile(incomplete, conv.id)

      # Conversation should be marked failed
      {:ok, updated} = Ash.get(Conversation, conv.id)
      assert updated.status == :failed
    end

    test "idempotent — running twice doesn't crash", %{conversation: conv, profile: profile} do
      assert {:ok, first} = Provisioner.from_profile(profile, conv.id)

      # Create a new conversation for second run (first is already completed/linked)
      {:ok, conv2} =
        Conversation
        |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
        |> Ash.create()

      assert {:ok, second} = Provisioner.from_profile(profile, conv2.id)

      # Same company (found by slug)
      assert first.company.id == second.company.id
    end
  end
end
