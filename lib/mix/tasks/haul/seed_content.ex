defmodule Mix.Tasks.Haul.SeedContent do
  @shortdoc "Seed content resources from priv/content/ files"
  @moduledoc """
  Seeds content resources (SiteConfig, Service, GalleryItem, Endorsement, Page)
  from YAML and markdown files in priv/content/.

  Idempotent — safe to run repeatedly. Existing records are matched by natural
  key and updated; new records are created.

  ## Usage

      mix haul.seed_content
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    alias Haul.Accounts.Company

    companies = Ash.read!(Company)

    if companies == [] do
      Mix.shell().info("No companies found. Run seeds.exs first to create a default company.")
      :ok
    else
      for company <- companies do
        tenant = Haul.Accounts.Changes.ProvisionTenant.tenant_schema(company.slug)
        summary = Haul.Content.Seeder.seed!(tenant)

        services_count = length(summary.services)
        gallery_count = length(summary.gallery_items)
        endorsements_count = length(summary.endorsements)
        pages_count = length(summary.pages)

        Mix.shell().info("""
        Seeded content for tenant "#{company.slug}":
          SiteConfig:   #{summary.site_config}
          Services:     #{services_count}
          Gallery:      #{gallery_count}
          Endorsements: #{endorsements_count}
          Pages:        #{pages_count}
        """)
      end

      :ok
    end
  end
end
