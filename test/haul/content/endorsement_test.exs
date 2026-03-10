defmodule Haul.Content.EndorsementTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.Endorsement

  @valid_attrs %{
    customer_name: "John Smith",
    quote_text: "Great service, highly recommend!",
    star_rating: 5,
    source: :google,
    date: ~D[2026-03-01]
  }

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Endorsement Test Co #{System.unique_integer([:positive])}"
      })
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant}" CASCADE))
    end)

    %{tenant: tenant}
  end

  describe "add" do
    test "creates an endorsement with valid attributes", %{tenant: tenant} do
      assert {:ok, endorsement} =
               Endorsement
               |> Ash.Changeset.for_create(:add, @valid_attrs, tenant: tenant)
               |> Ash.create()

      assert endorsement.customer_name == "John Smith"
      assert endorsement.quote_text == "Great service, highly recommend!"
      assert endorsement.star_rating == 5
      assert endorsement.source == :google
      assert endorsement.date == ~D[2026-03-01]
      assert endorsement.featured == false
      assert endorsement.active == true
    end

    test "requires customer_name and quote_text", %{tenant: tenant} do
      assert {:error, _} =
               Endorsement
               |> Ash.Changeset.for_create(:add, %{star_rating: 5}, tenant: tenant)
               |> Ash.create()
    end

    test "star_rating is optional", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :star_rating)

      assert {:ok, endorsement} =
               Endorsement
               |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
               |> Ash.create()

      assert is_nil(endorsement.star_rating)
    end

    test "rejects invalid star_rating below 1", %{tenant: tenant} do
      attrs = Map.put(@valid_attrs, :star_rating, 0)

      assert {:error, _} =
               Endorsement
               |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
               |> Ash.create()
    end

    test "rejects invalid star_rating above 5", %{tenant: tenant} do
      attrs = Map.put(@valid_attrs, :star_rating, 6)

      assert {:error, _} =
               Endorsement
               |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
               |> Ash.create()
    end

    test "accepts all valid source values", %{tenant: tenant} do
      for source <- [:google, :yelp, :direct, :facebook] do
        attrs =
          Map.merge(@valid_attrs, %{
            source: source,
            customer_name: "#{source} user #{System.unique_integer([:positive])}"
          })

        assert {:ok, endorsement} =
                 Endorsement
                 |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
                 |> Ash.create()

        assert endorsement.source == source
      end
    end
  end

  describe "job relationship" do
    test "endorsement can exist without a job", %{tenant: tenant} do
      assert {:ok, endorsement} =
               Endorsement
               |> Ash.Changeset.for_create(:add, @valid_attrs, tenant: tenant)
               |> Ash.create()

      assert is_nil(endorsement.job_id)
    end
  end
end
