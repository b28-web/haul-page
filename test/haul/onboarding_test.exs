defmodule Haul.OnboardingTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.{Company, User}
  alias Haul.Content.SiteConfig

  setup do
    unique = System.unique_integer([:positive])

    on_exit(fn ->
      # Clean up any tenant schemas created during this test
      for slug <- ["joe-s-hauling-#{unique}", "minimal-co-#{unique}", "test-hauling-#{unique}"] do
        Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "tenant_#{slug}" CASCADE))
      end
    end)

    %{unique: unique}
  end

  defp valid_params(unique, overrides \\ %{}) do
    Map.merge(
      %{
        name: "Joe's Hauling #{unique}",
        phone: "555-1234",
        email: "joe-#{unique}@example.com",
        area: "Seattle, WA"
      },
      overrides
    )
  end

  describe "run/1" do
    test "onboards a new operator end-to-end", %{unique: unique} do
      params = valid_params(unique)
      assert {:ok, result} = Haul.Onboarding.run(params)

      # Company created
      assert result.company.name == "Joe's Hauling #{unique}"
      assert result.company.slug == "joe-s-hauling-#{unique}"
      assert result.existing_company == false

      # Tenant schema matches
      assert result.tenant == "tenant_joe-s-hauling-#{unique}"

      # Content seeded from defaults pack
      assert is_map(result.content)
      assert length(result.content.services) == 6
      assert length(result.content.gallery_items) == 4
      assert length(result.content.endorsements) == 3

      # Owner user created
      assert to_string(result.user.email) == "joe-#{unique}@example.com"
      assert result.user.role == :owner

      # SiteConfig updated with operator info
      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.phone == "555-1234"
      assert config.email == "joe-#{unique}@example.com"
      assert config.service_area == "Seattle, WA"
    end

    test "idempotent — re-run updates instead of duplicating", %{unique: unique} do
      params = valid_params(unique)

      assert {:ok, first} = Haul.Onboarding.run(params)
      assert {:ok, second} = Haul.Onboarding.run(params)

      # Same company
      assert first.company.id == second.company.id
      assert second.existing_company == true

      # Same user
      assert first.user.id == second.user.id

      # Only one company with this slug
      companies = Ash.read!(Company)
      assert length(Enum.filter(companies, &(&1.slug == "joe-s-hauling-#{unique}"))) == 1

      # Only one user in tenant
      users = Ash.read!(User, tenant: second.tenant, authorize?: false)

      assert length(Enum.filter(users, &(to_string(&1.email) == "joe-#{unique}@example.com"))) ==
               1
    end

    test "updates company name on re-run with same slug", %{unique: unique} do
      assert {:ok, first} = Haul.Onboarding.run(valid_params(unique))
      assert first.company.name == "Joe's Hauling #{unique}"

      # Re-run with slightly different name that produces the same slug
      assert {:ok, second} =
               Haul.Onboarding.run(valid_params(unique, %{name: "Joe's  Hauling #{unique}"}))

      assert second.company.id == first.company.id
      assert second.existing_company == true
    end

    test "requires name" do
      assert {:error, :validation, "name is required"} =
               Haul.Onboarding.run(%{email: "joe@ex.com"})
    end

    test "requires email" do
      assert {:error, :validation, "email is required"} =
               Haul.Onboarding.run(%{name: "Test Co"})
    end

    test "handles empty name" do
      assert {:error, :validation, "name is required"} =
               Haul.Onboarding.run(%{name: "", email: "joe@ex.com"})
    end

    test "handles empty email" do
      assert {:error, :validation, "email is required"} =
               Haul.Onboarding.run(%{name: "Test Co", email: ""})
    end

    test "works with minimal params (no phone or area)", %{unique: unique} do
      params = %{name: "Minimal Co #{unique}", email: "min-#{unique}@example.com"}

      assert {:ok, result} = Haul.Onboarding.run(params)
      assert result.company.slug == "minimal-co-#{unique}"
      assert to_string(result.user.email) == "min-#{unique}@example.com"
    end
  end
end
