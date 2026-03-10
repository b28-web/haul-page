defmodule Haul.TenantIsolationTest do
  @moduledoc """
  Comprehensive tenant isolation tests. Verifies that data created in one
  tenant schema is never visible from another tenant's context — across
  all tenant-scoped resources (Jobs, Users, Content).

  These tests are the security backbone of the multi-tenant platform.
  """
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Accounts.User
  alias Haul.Content.Endorsement
  alias Haul.Content.GalleryItem
  alias Haul.Content.Service
  alias Haul.Content.SiteConfig
  alias Haul.Operations.Job

  # ── Helpers ──────────────────────────────────────────────────────────

  defp create_tenant(name) do
    unique_name = "#{name} #{System.unique_integer([:positive])}"

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: unique_name})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)
    {company, tenant}
  end

  defp register_owner(tenant, email) do
    {:ok, user} =
      User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{email: email, password: "Password123!", password_confirmation: "Password123!"},
        tenant: tenant,
        authorize?: false
      )
      |> Ash.create()

    {:ok, user} =
      user
      |> Ash.Changeset.for_update(:update_user, %{role: :owner},
        tenant: tenant,
        authorize?: false
      )
      |> Ash.update()

    user
  end

  defp create_job(tenant, attrs) do
    defaults = %{
      customer_phone: "555-0000",
      address: "123 Test St",
      item_description: "Misc junk"
    }

    Job
    |> Ash.Changeset.for_create(:create_from_online_booking, Map.merge(defaults, attrs),
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  defp create_site_config(tenant, attrs) do
    defaults = %{phone: "555-0000"}

    SiteConfig
    |> Ash.Changeset.for_create(:create_default, Map.merge(defaults, attrs),
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  defp create_service(tenant, title) do
    Service
    |> Ash.Changeset.for_create(
      :add,
      %{title: title, description: "#{title} desc", icon: "truck"},
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  defp create_gallery_item(tenant, caption) do
    GalleryItem
    |> Ash.Changeset.for_create(
      :add,
      %{
        before_image_url: "/before-#{caption}.jpg",
        after_image_url: "/after-#{caption}.jpg",
        caption: caption
      },
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  defp create_endorsement(tenant, customer_name) do
    Endorsement
    |> Ash.Changeset.for_create(
      :add,
      %{customer_name: customer_name, quote_text: "Great work by #{customer_name}!"},
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  # ── Setup ────────────────────────────────────────────────────────────

  setup do
    {company_a, tenant_a} = create_tenant("Alpha Hauling")
    {company_b, tenant_b} = create_tenant("Beta Removal")

    owner_a = register_owner(tenant_a, "owner@alpha.com")
    owner_b = register_owner(tenant_b, "owner@beta.com")

    job_a =
      create_job(tenant_a, %{customer_name: "Alice Customer", customer_email: "alice@example.com"})

    job_b =
      create_job(tenant_b, %{customer_name: "Bob Customer", customer_email: "bob@example.com"})

    config_a = create_site_config(tenant_a, %{business_name: "Alpha Hauling LLC"})
    config_b = create_site_config(tenant_b, %{business_name: "Beta Removal Inc"})

    service_a = create_service(tenant_a, "Garage Cleanout")
    service_b = create_service(tenant_b, "Office Clearance")

    gallery_a = create_gallery_item(tenant_a, "alpha-yard")
    gallery_b = create_gallery_item(tenant_b, "beta-basement")

    endorsement_a = create_endorsement(tenant_a, "Alice Fan")
    endorsement_b = create_endorsement(tenant_b, "Bob Fan")

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant_a}" CASCADE))
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant_b}" CASCADE))
    end)

    %{
      company_a: company_a,
      company_b: company_b,
      tenant_a: tenant_a,
      tenant_b: tenant_b,
      owner_a: owner_a,
      owner_b: owner_b,
      job_a: job_a,
      job_b: job_b,
      config_a: config_a,
      config_b: config_b,
      service_a: service_a,
      service_b: service_b,
      gallery_a: gallery_a,
      gallery_b: gallery_b,
      endorsement_a: endorsement_a,
      endorsement_b: endorsement_b
    }
  end

  # ── Job Isolation ────────────────────────────────────────────────────

  describe "job isolation" do
    test "query jobs as tenant A returns only A's jobs", ctx do
      jobs = Job |> Ash.read!(tenant: ctx.tenant_a, authorize?: false)

      assert length(jobs) == 1
      assert hd(jobs).customer_name == "Alice Customer"
    end

    test "query jobs as tenant B returns only B's jobs", ctx do
      jobs = Job |> Ash.read!(tenant: ctx.tenant_b, authorize?: false)

      assert length(jobs) == 1
      assert hd(jobs).customer_name == "Bob Customer"
    end

    test "job created in tenant A is not visible in tenant B", ctx do
      _new_job =
        create_job(ctx.tenant_a, %{
          customer_name: "Charlie Extra",
          customer_email: "charlie@example.com"
        })

      jobs_a = Job |> Ash.read!(tenant: ctx.tenant_a, authorize?: false)
      jobs_b = Job |> Ash.read!(tenant: ctx.tenant_b, authorize?: false)

      names_a = Enum.map(jobs_a, & &1.customer_name)
      names_b = Enum.map(jobs_b, & &1.customer_name)

      assert "Charlie Extra" in names_a
      refute "Charlie Extra" in names_b
      assert length(jobs_b) == 1
    end
  end

  # ── Content Isolation ────────────────────────────────────────────────

  describe "content isolation" do
    test "SiteConfig is scoped to tenant", ctx do
      configs_a = SiteConfig |> Ash.read!(tenant: ctx.tenant_a, authorize?: false)
      configs_b = SiteConfig |> Ash.read!(tenant: ctx.tenant_b, authorize?: false)

      assert length(configs_a) == 1
      assert hd(configs_a).business_name == "Alpha Hauling LLC"

      assert length(configs_b) == 1
      assert hd(configs_b).business_name == "Beta Removal Inc"
    end

    test "Services are scoped to tenant", ctx do
      services_a = Service |> Ash.read!(tenant: ctx.tenant_a, authorize?: false)
      services_b = Service |> Ash.read!(tenant: ctx.tenant_b, authorize?: false)

      titles_a = Enum.map(services_a, & &1.title)
      titles_b = Enum.map(services_b, & &1.title)

      assert "Garage Cleanout" in titles_a
      refute "Office Clearance" in titles_a

      assert "Office Clearance" in titles_b
      refute "Garage Cleanout" in titles_b
    end

    test "GalleryItems are scoped to tenant", ctx do
      items_a = GalleryItem |> Ash.read!(tenant: ctx.tenant_a, authorize?: false)
      items_b = GalleryItem |> Ash.read!(tenant: ctx.tenant_b, authorize?: false)

      assert length(items_a) == 1
      assert hd(items_a).caption == "alpha-yard"

      assert length(items_b) == 1
      assert hd(items_b).caption == "beta-basement"
    end

    test "Endorsements are scoped to tenant", ctx do
      endorsements_a = Endorsement |> Ash.read!(tenant: ctx.tenant_a, authorize?: false)
      endorsements_b = Endorsement |> Ash.read!(tenant: ctx.tenant_b, authorize?: false)

      assert length(endorsements_a) == 1
      assert hd(endorsements_a).customer_name == "Alice Fan"

      assert length(endorsements_b) == 1
      assert hd(endorsements_b).customer_name == "Bob Fan"
    end
  end

  # ── Authentication Boundary ──────────────────────────────────────────

  describe "authentication boundary" do
    test "user in tenant A cannot authenticate into tenant B", ctx do
      result =
        User
        |> Ash.Query.for_read(
          :sign_in_with_password,
          %{email: "owner@alpha.com", password: "Password123!"},
          tenant: ctx.tenant_b
        )
        |> Ash.read_one()

      # User doesn't exist in tenant B's schema, so auth fails
      assert {:error, _} = result
    end
  end

  # ── Missing Tenant Context ──────────────────────────────────────────

  describe "missing tenant context" do
    test "action without tenant context is rejected" do
      assert_raise Ash.Error.Invalid, ~r/require a tenant/, fn ->
        Job |> Ash.read!(authorize?: false)
      end
    end
  end

  # ── Defense in Depth ─────────────────────────────────────────────────

  describe "defense in depth" do
    test "direct Ecto query with wrong schema prefix returns empty", ctx do
      # Tenant A's job should NOT appear in tenant B's schema
      {:ok, result} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          "SELECT customer_name FROM \"#{ctx.tenant_b}\".jobs WHERE customer_name = $1",
          ["Alice Customer"]
        )

      assert result.rows == []

      # And vice versa
      {:ok, result} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          "SELECT customer_name FROM \"#{ctx.tenant_a}\".jobs WHERE customer_name = $1",
          ["Bob Customer"]
        )

      assert result.rows == []
    end
  end
end
