defmodule HaulWeb.ContentHelpers do
  @moduledoc false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.{Endorsement, GalleryItem, Service, SiteConfig}

  @doc """
  Returns the tenant schema name derived from operator config slug.
  """
  def resolve_tenant do
    operator = Application.get_env(:haul, :operator, [])
    ProvisionTenant.tenant_schema(operator[:slug] || "default")
  end

  @doc """
  Loads SiteConfig from Ash for the given tenant.
  Falls back to operator config values if no record exists or query fails.
  """
  def load_site_config(tenant) do
    case Ash.read(SiteConfig, tenant: tenant) do
      {:ok, [config | _]} -> config
      _ -> fallback_site_config()
    end
  end

  @doc """
  Loads active services from Ash for the given tenant.
  Falls back to operator config services if query fails.
  """
  def load_services(tenant) do
    case Ash.read(Service, tenant: tenant) do
      {:ok, services} when services != [] ->
        Enum.filter(services, & &1.active)

      _ ->
        fallback_services()
    end
  end

  @doc """
  Loads active gallery items from Ash for the given tenant.
  Returns empty list if query fails.
  """
  def load_gallery_items(tenant) do
    case Ash.read(GalleryItem, tenant: tenant) do
      {:ok, items} ->
        items
        |> Enum.filter(& &1.active)
        |> Enum.sort_by(& &1.sort_order)

      _ ->
        []
    end
  end

  @doc """
  Loads active endorsements from Ash for the given tenant.
  Returns empty list if query fails.
  """
  def load_endorsements(tenant) do
    case Ash.read(Endorsement, tenant: tenant) do
      {:ok, endorsements} -> Enum.filter(endorsements, & &1.active)
      _ -> []
    end
  end

  defp fallback_site_config do
    operator = Application.get_env(:haul, :operator, [])

    %{
      business_name: operator[:business_name],
      phone: operator[:phone],
      email: operator[:email],
      tagline: operator[:tagline],
      service_area: operator[:service_area],
      coupon_text: operator[:coupon_text] || "10% OFF"
    }
  end

  defp fallback_services do
    operator = Application.get_env(:haul, :operator, [])
    operator[:services] || []
  end
end
