defmodule Haul.Test.Factories do
  @moduledoc """
  Factory functions for test data creation. Standalone module with no
  dependencies on ConnCase or DataCase — calls Ash directly.

  ## Core factories (account-level)

  - `build_company/1` — creates a Company with unique name
  - `build_user/2` — registers a user with JWT in a tenant
  - `build_authenticated_context/1` — full company + tenant + user + token
  - `build_admin_session/0` — admin user with JWT

  ## Resource factories (tenant-scoped)

  All resource factories take `(tenant, attrs \\\\ %{})` and return the created resource.
  They use `authorize?: false` — tests needing authorization should set up policies explicitly.

  - `build_service/2` — Service with defaults (title, description, icon)
  - `build_gallery_item/2` — GalleryItem with defaults (before/after image URLs)
  - `build_endorsement/2` — Endorsement with defaults (customer_name, quote_text)
  - `build_site_config/2` — SiteConfig with defaults (business_name, phone)
  - `build_page/2` — Page with defaults (slug, title, body)
  - `build_booking_job/2` — Job in :lead state with defaults (customer info, address)
  """

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Accounts.User
  alias Haul.Content.{Endorsement, GalleryItem, Page, Service, SiteConfig}
  alias Haul.Operations.Job

  @doc """
  Creates a Company with a unique name. Accepts optional `:name` or `:company_name` override.
  """
  def build_company(attrs \\ %{}) do
    name = attrs[:company_name] || attrs[:name] || "Test Co #{System.unique_integer([:positive])}"

    create_attrs = %{name: name}
    create_attrs = if attrs[:slug], do: Map.put(create_attrs, :slug, attrs[:slug]), else: create_attrs

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, create_attrs)
      |> Ash.create()

    company
  end

  @doc """
  Provisions the tenant schema for a company. Returns the tenant string.
  """
  def provision_tenant(company) do
    ProvisionTenant.tenant_schema(company.slug)
  end

  @doc """
  Registers a user in the given tenant, sets their role, and generates a JWT.
  Returns `%{user: user, token: token}`.

  Options:
  - `:email` — defaults to `"admin@example.com"`
  - `:role` — defaults to `:owner`
  """
  def build_user(tenant, attrs \\ %{}) do
    user_attrs = %{
      email: attrs[:email] || "admin@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    }

    {:ok, user} =
      User
      |> Ash.Changeset.for_create(:register_with_password, user_attrs,
        tenant: tenant,
        authorize?: false
      )
      |> Ash.create()

    role = attrs[:role] || :owner

    {:ok, user} =
      user
      |> Ash.Changeset.for_update(:update_user, %{role: role},
        tenant: tenant,
        authorize?: false
      )
      |> Ash.update()

    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

    %{user: user, token: token}
  end

  @doc """
  Creates a company, provisions its tenant, registers an owner user, and returns
  the full auth context: `%{company, tenant, user, token}`.

  Accepts all options from `build_company/1` and `build_user/2`.
  """
  def build_authenticated_context(attrs \\ %{}) do
    company = build_company(attrs)
    tenant = provision_tenant(company)
    %{user: user, token: token} = build_user(tenant, attrs)

    %{company: company, tenant: tenant, user: user, token: token}
  end

  @doc """
  Creates a completed AdminUser and returns `%{admin, token}`.
  """
  def build_admin_session(_attrs \\ %{}) do
    alias Haul.Admin.AdminUser

    email = "admin-#{System.unique_integer([:positive])}@test.com"
    password = "SuperSecure123!"

    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

    {:ok, admin} =
      AdminUser
      |> Ash.Changeset.for_create(
        :create_bootstrap,
        %{email: email, setup_token_hash_value: token_hash},
        authorize?: false
      )
      |> Ash.create()

    hashed = Bcrypt.hash_pwd_salt(password)

    {:ok, _admin} =
      admin
      |> Ash.Changeset.for_update(:complete_setup, %{hashed_password: hashed}, authorize?: false)
      |> Ash.update()

    {:ok, completed_admin} =
      AdminUser
      |> Ash.Query.for_read(:sign_in_with_password, %{email: email, password: password})
      |> Ash.read_one()

    token = completed_admin.__metadata__.token
    %{admin: completed_admin, token: token}
  end

  # ---------------------------------------------------------------------------
  # Resource factories (tenant-scoped)
  # ---------------------------------------------------------------------------

  @doc """
  Creates a Service with sensible defaults. Override any attribute via `attrs`.
  """
  def build_service(tenant, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    defaults = %{
      title: "Test Service #{n}",
      description: "Test service description",
      icon: "truck"
    }

    Service
    |> Ash.Changeset.for_create(:add, Map.merge(defaults, attrs), tenant: tenant, authorize?: false)
    |> Ash.create!()
  end

  @doc """
  Creates a GalleryItem with sensible defaults. Override any attribute via `attrs`.
  """
  def build_gallery_item(tenant, attrs \\ %{}) do
    defaults = %{
      before_image_url: "/uploads/test/before.jpg",
      after_image_url: "/uploads/test/after.jpg",
      caption: "Test item",
      alt_text: "Before and after test"
    }

    GalleryItem
    |> Ash.Changeset.for_create(:add, Map.merge(defaults, attrs), tenant: tenant, authorize?: false)
    |> Ash.create!()
  end

  @doc """
  Creates an Endorsement with sensible defaults. Override any attribute via `attrs`.
  """
  def build_endorsement(tenant, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    defaults = %{
      customer_name: "Test Customer #{n}",
      quote_text: "Great service!"
    }

    Endorsement
    |> Ash.Changeset.for_create(:add, Map.merge(defaults, attrs), tenant: tenant, authorize?: false)
    |> Ash.create!()
  end

  @doc """
  Creates a SiteConfig with sensible defaults. Override any attribute via `attrs`.
  """
  def build_site_config(tenant, attrs \\ %{}) do
    defaults = %{
      business_name: "Test Business",
      phone: "555-0100"
    }

    SiteConfig
    |> Ash.Changeset.for_create(:create_default, Map.merge(defaults, attrs), tenant: tenant, authorize?: false)
    |> Ash.create!()
  end

  @doc """
  Creates a Page with sensible defaults. Override any attribute via `attrs`.
  """
  def build_page(tenant, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    defaults = %{
      slug: "test-page-#{n}",
      title: "Test Page #{n}",
      body: "Test content"
    }

    Page
    |> Ash.Changeset.for_create(:draft, Map.merge(defaults, attrs), tenant: tenant, authorize?: false)
    |> Ash.create!()
  end

  @doc """
  Creates a Job in `:lead` state with sensible defaults. Override any attribute via `attrs`.
  """
  def build_booking_job(tenant, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    defaults = %{
      customer_name: "Test Customer #{n}",
      customer_phone: "555-0100",
      address: "123 Test St",
      item_description: "Old couch"
    }

    Job
    |> Ash.Changeset.for_create(:create_from_online_booking, Map.merge(defaults, attrs),
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  @doc """
  Drops all tenant schemas except the shared test tenant.
  Uses `query` (not `query!`) to tolerate concurrent cleanup deadlocks.
  """
  def cleanup_all_tenants do
    {:ok, result} =
      Ecto.Adapters.SQL.query(Haul.Repo, """
      SELECT schema_name FROM information_schema.schemata
      WHERE schema_name LIKE 'tenant_%'
        AND schema_name != 'tenant_shared-test-co'
      """)

    for [schema] <- result.rows do
      Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE")
    end
  end
end
