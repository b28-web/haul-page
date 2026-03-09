defmodule Haul.Content.Seeder do
  @moduledoc false

  alias Haul.Content.{Endorsement, GalleryItem, Page, Service, SiteConfig}

  @doc """
  Seeds all content resources for the given tenant from YAML/markdown files
  in priv/content/. Idempotent — safe to run repeatedly.

  Returns a summary map with counts per resource type.
  """
  def seed!(tenant) do
    %{
      site_config: seed_site_config(tenant),
      services: seed_services(tenant),
      gallery_items: seed_gallery_items(tenant),
      endorsements: seed_endorsements(tenant),
      pages: seed_pages(tenant)
    }
  end

  defp seed_site_config(tenant) do
    path = content_path("site_config.yml")

    if File.exists?(path) do
      attrs = read_yaml!(path)

      case Ash.read!(SiteConfig, tenant: tenant) do
        [] ->
          SiteConfig
          |> Ash.Changeset.for_create(:create_default, attrs, tenant: tenant)
          |> Ash.create!()

          :created

        [existing] ->
          existing
          |> Ash.Changeset.for_update(:edit, attrs)
          |> Ash.update!()

          :updated
      end
    else
      :skipped
    end
  end

  defp seed_services(tenant) do
    files = glob_yaml("services")
    existing = Ash.read!(Service, tenant: tenant)
    by_title = Map.new(existing, &{&1.title, &1})

    Enum.map(files, fn file ->
      attrs = read_yaml!(file)
      title = attrs["title"]

      case Map.get(by_title, title) do
        nil ->
          Service
          |> Ash.Changeset.for_create(:add, atomize(attrs), tenant: tenant)
          |> Ash.create!()

          :created

        record ->
          record
          |> Ash.Changeset.for_update(:edit, atomize(attrs))
          |> Ash.update!()

          :updated
      end
    end)
  end

  defp seed_gallery_items(tenant) do
    files = glob_yaml("gallery")
    existing = Ash.read!(GalleryItem, tenant: tenant)
    by_url = Map.new(existing, &{&1.before_image_url, &1})

    Enum.map(files, fn file ->
      attrs = read_yaml!(file)
      url = attrs["before_image_url"]

      case Map.get(by_url, url) do
        nil ->
          GalleryItem
          |> Ash.Changeset.for_create(:add, atomize(attrs), tenant: tenant)
          |> Ash.create!()

          :created

        record ->
          edit_attrs = Map.drop(attrs, ["before_image_url", "after_image_url"])

          record
          |> Ash.Changeset.for_update(:edit, atomize(edit_attrs))
          |> Ash.update!()

          :updated
      end
    end)
  end

  defp seed_endorsements(tenant) do
    files = glob_yaml("endorsements")
    existing = Ash.read!(Endorsement, tenant: tenant)
    by_name = Map.new(existing, &{&1.customer_name, &1})

    Enum.map(files, fn file ->
      attrs = read_yaml!(file)
      name = attrs["customer_name"]

      attrs =
        if date_str = attrs["date"] do
          Map.put(attrs, "date", Date.from_iso8601!(date_str))
        else
          attrs
        end

      case Map.get(by_name, name) do
        nil ->
          Endorsement
          |> Ash.Changeset.for_create(:add, atomize(attrs), tenant: tenant)
          |> Ash.create!()

          :created

        record ->
          record
          |> Ash.Changeset.for_update(:edit, atomize(attrs))
          |> Ash.update!()

          :updated
      end
    end)
  end

  defp seed_pages(tenant) do
    files = glob_files("pages", "*.md")
    existing = Ash.read!(Page, tenant: tenant)
    by_slug = Map.new(existing, &{&1.slug, &1})

    Enum.map(files, fn file ->
      content = File.read!(file)
      {frontmatter, body} = parse_frontmatter!(content)
      slug = frontmatter["slug"]
      attrs = Map.put(frontmatter, "body", body)

      case Map.get(by_slug, slug) do
        nil ->
          Page
          |> Ash.Changeset.for_create(:draft, atomize(attrs), tenant: tenant)
          |> Ash.create!()

          :created

        record ->
          edit_attrs = Map.drop(attrs, ["slug"])

          record
          |> Ash.Changeset.for_update(:edit, atomize(edit_attrs))
          |> Ash.update!()

          :updated
      end
    end)
  end

  @doc """
  Parses YAML frontmatter from a markdown file content string.
  Returns {frontmatter_map, body_string}.
  """
  def parse_frontmatter!(content) do
    case Regex.run(~r/\A---\n(.+?)\n---\n(.*)\z/s, content) do
      [_, yaml, body] ->
        {YamlElixir.read_from_string!(yaml), String.trim(body)}

      nil ->
        raise "Invalid frontmatter format — expected ---\\n...\\n---\\n"
    end
  end

  defp content_path(relative) do
    :haul
    |> :code.priv_dir()
    |> Path.join("content/#{relative}")
  end

  defp glob_yaml(subdir) do
    glob_files(subdir, "*.yml")
  end

  defp glob_files(subdir, pattern) do
    content_path(subdir)
    |> Path.join(pattern)
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp read_yaml!(path) do
    YamlElixir.read_from_file!(path)
  end

  defp atomize(map) do
    Map.new(map, fn {k, v} -> {String.to_existing_atom(k), v} end)
  end
end
