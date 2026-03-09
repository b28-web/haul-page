defmodule Haul.OnboardingTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.{Company, User}
  alias Haul.Content.SiteConfig

  setup do
    on_exit(fn ->
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    :ok
  end

  defp valid_params(overrides \\ %{}) do
    Map.merge(
      %{
        name: "Joe's Hauling",
        phone: "555-1234",
        email: "joe@example.com",
        area: "Seattle, WA"
      },
      overrides
    )
  end

  describe "run/1" do
    test "onboards a new operator end-to-end" do
      assert {:ok, result} = Haul.Onboarding.run(valid_params())

      # Company created
      assert result.company.name == "Joe's Hauling"
      assert result.company.slug == "joe-s-hauling"
      assert result.existing_company == false

      # Tenant schema matches
      assert result.tenant == "tenant_joe-s-hauling"

      # Content seeded from defaults pack
      assert is_map(result.content)
      assert length(result.content.services) == 6
      assert length(result.content.gallery_items) == 4
      assert length(result.content.endorsements) == 3

      # Owner user created
      assert to_string(result.user.email) == "joe@example.com"
      assert result.user.role == :owner

      # SiteConfig updated with operator info
      [config] = Ash.read!(SiteConfig, tenant: result.tenant)
      assert config.phone == "555-1234"
      assert config.email == "joe@example.com"
      assert config.service_area == "Seattle, WA"
    end

    test "idempotent — re-run updates instead of duplicating" do
      params = valid_params()

      assert {:ok, first} = Haul.Onboarding.run(params)
      assert {:ok, second} = Haul.Onboarding.run(params)

      # Same company
      assert first.company.id == second.company.id
      assert second.existing_company == true

      # Same user
      assert first.user.id == second.user.id

      # Only one company with this slug
      companies = Ash.read!(Company)
      assert length(Enum.filter(companies, &(&1.slug == "joe-s-hauling"))) == 1

      # Only one user in tenant
      users = Ash.read!(User, tenant: second.tenant, authorize?: false)
      assert length(Enum.filter(users, &(to_string(&1.email) == "joe@example.com"))) == 1
    end

    test "updates company name on re-run with same slug" do
      assert {:ok, first} = Haul.Onboarding.run(valid_params())
      assert first.company.name == "Joe's Hauling"

      # Re-run with slightly different name that produces the same slug
      assert {:ok, second} =
               Haul.Onboarding.run(valid_params(%{name: "Joe's  Hauling"}))

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

    test "works with minimal params (no phone or area)" do
      params = %{name: "Minimal Co", email: "min@example.com"}

      assert {:ok, result} = Haul.Onboarding.run(params)
      assert result.company.slug == "minimal-co"
      assert to_string(result.user.email) == "min@example.com"
    end
  end

  describe "derive_slug/1" do
    test "lowercases and hyphenates" do
      assert Haul.Onboarding.derive_slug("Joe's Hauling") == "joe-s-hauling"
    end

    test "handles special characters" do
      assert Haul.Onboarding.derive_slug("A & B Junk Co.") == "a-b-junk-co"
    end

    test "trims leading/trailing hyphens" do
      assert Haul.Onboarding.derive_slug("  Test Co  ") == "test-co"
    end

    test "collapses multiple separators" do
      assert Haul.Onboarding.derive_slug("foo---bar") == "foo-bar"
    end
  end

  describe "site_url/1" do
    test "constructs URL with base domain" do
      url = Haul.Onboarding.site_url("test-co")
      assert url =~ "test-co."
      assert url =~ "https://"
    end
  end
end
