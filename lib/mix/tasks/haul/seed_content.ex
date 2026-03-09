defmodule Mix.Tasks.Haul.SeedContent do
  @shortdoc "Seed content resources from priv/content/ files"
  @moduledoc """
  Seeds content resources (SiteConfig, Service, GalleryItem, Endorsement, Page)
  from YAML and markdown files in priv/content/.

  Idempotent — safe to run repeatedly. Existing records are matched by natural
  key and updated; new records are created.

  ## Usage

      mix haul.seed_content
      mix haul.seed_content --operator customer-1
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [operator: :string])

    case opts[:operator] do
      nil -> seed_all_companies()
      slug -> seed_operator(slug)
    end
  end

  defp seed_all_companies do
    alias Haul.Accounts.Company

    companies = Ash.read!(Company)

    if companies == [] do
      Mix.shell().info("No companies found. Run seeds.exs first to create a default company.")
    else
      for company <- companies do
        tenant = Haul.Accounts.Changes.ProvisionTenant.tenant_schema(company.slug)
        summary = Haul.Content.Seeder.seed!(tenant)
        print_summary(company.slug, summary)
      end
    end

    :ok
  end

  defp seed_operator(slug) do
    alias Haul.Accounts.Company

    content_root = operator_content_root(slug)

    unless File.dir?(content_root) do
      Mix.raise("Content directory not found: #{content_root}")
    end

    # Find or create the company for this operator
    company =
      case Ash.read!(Company) |> Enum.find(&(&1.slug == slug)) do
        nil ->
          # Read business name from the operator's site_config
          config_path = Path.join(content_root, "site_config.yml")

          name =
            if File.exists?(config_path) do
              config_path |> YamlElixir.read_from_file!() |> Map.get("business_name", slug)
            else
              slug
            end

          Company
          |> Ash.Changeset.for_create(:create_company, %{name: name, slug: slug})
          |> Ash.create!()

        existing ->
          existing
      end

    tenant = Haul.Accounts.Changes.ProvisionTenant.tenant_schema(company.slug)
    summary = Haul.Content.Seeder.seed!(tenant, content_root)
    print_summary(company.slug, summary)

    :ok
  end

  defp operator_content_root(slug) do
    :haul
    |> :code.priv_dir()
    |> Path.join("content/operators/#{slug}")
  end

  defp print_summary(slug, summary) do
    services_count = length(summary.services)
    gallery_count = length(summary.gallery_items)
    endorsements_count = length(summary.endorsements)
    pages_count = length(summary.pages)

    Mix.shell().info("""
    Seeded content for tenant "#{slug}":
      SiteConfig:   #{summary.site_config}
      Services:     #{services_count}
      Gallery:      #{gallery_count}
      Endorsements: #{endorsements_count}
      Pages:        #{pages_count}
    """)
  end
end
