defmodule Haul.Content.DefaultsTest do
  use ExUnit.Case, async: true

  @defaults_root Path.join(:code.priv_dir(:haul), "content/defaults")

  describe "default content pack structure" do
    test "site_config.yml exists and parses" do
      path = Path.join(@defaults_root, "site_config.yml")
      assert File.exists?(path)

      config = YamlElixir.read_from_file!(path)
      assert is_binary(config["business_name"])
      assert is_binary(config["phone"])
      assert is_binary(config["tagline"])
    end

    test "6 service YAML files exist and parse" do
      files = Path.join(@defaults_root, "services/*.yml") |> Path.wildcard() |> Enum.sort()
      assert length(files) == 6

      for file <- files do
        service = YamlElixir.read_from_file!(file)
        assert is_binary(service["title"]), "#{file} missing title"
        assert is_binary(service["description"]), "#{file} missing description"
        assert is_binary(service["icon"]), "#{file} missing icon"
        assert is_integer(service["sort_order"]), "#{file} missing sort_order"
      end
    end

    test "services match expected titles" do
      files = Path.join(@defaults_root, "services/*.yml") |> Path.wildcard()

      titles =
        files
        |> Enum.map(&YamlElixir.read_from_file!/1)
        |> Enum.map(& &1["title"])
        |> Enum.sort()

      expected = ["Assembly", "Cleanouts", "Junk Removal", "Moving Help", "Repairs", "Yard Waste"]
      assert titles == expected
    end

    test "3 endorsement YAML files exist and parse" do
      files = Path.join(@defaults_root, "endorsements/*.yml") |> Path.wildcard()
      assert length(files) == 3

      for file <- files do
        endorsement = YamlElixir.read_from_file!(file)
        assert is_binary(endorsement["customer_name"]), "#{file} missing customer_name"
        assert is_binary(endorsement["quote_text"]), "#{file} missing quote_text"
        assert endorsement["star_rating"] in 1..5, "#{file} invalid star_rating"

        assert String.contains?(endorsement["customer_name"], "(Sample)"),
               "#{file} should be marked as sample"
      end
    end

    test "4 gallery YAML files exist and parse" do
      files = Path.join(@defaults_root, "gallery/*.yml") |> Path.wildcard()
      assert length(files) == 4

      for file <- files do
        item = YamlElixir.read_from_file!(file)
        assert is_binary(item["before_image_url"]), "#{file} missing before_image_url"
        assert is_binary(item["after_image_url"]), "#{file} missing after_image_url"
        assert is_binary(item["caption"]), "#{file} missing caption"
      end
    end

    test "gallery SVG files referenced by defaults exist" do
      files = Path.join(@defaults_root, "gallery/*.yml") |> Path.wildcard()
      static_root = Path.join(:code.priv_dir(:haul), "static")

      for file <- files do
        item = YamlElixir.read_from_file!(file)

        for key <- ["before_image_url", "after_image_url"] do
          url = item[key]
          # URLs like "/images/gallery/before-1.svg" map to priv/static/images/...
          path = Path.join(static_root, url)
          assert File.exists?(path), "SVG not found: #{url} (from #{file})"
        end
      end
    end

    test "2 page markdown files exist with valid frontmatter" do
      files = Path.join(@defaults_root, "pages/*.md") |> Path.wildcard()
      assert length(files) == 2

      for file <- files do
        content = File.read!(file)
        {frontmatter, body} = Haul.Content.Seeder.parse_frontmatter!(content)
        assert is_binary(frontmatter["slug"]), "#{file} missing slug"
        assert is_binary(frontmatter["title"]), "#{file} missing title"
        assert byte_size(body) > 0, "#{file} has empty body"
      end
    end

    test "page slugs are about and faq" do
      files = Path.join(@defaults_root, "pages/*.md") |> Path.wildcard()

      slugs =
        files
        |> Enum.map(fn file ->
          content = File.read!(file)
          {frontmatter, _body} = Haul.Content.Seeder.parse_frontmatter!(content)
          frontmatter["slug"]
        end)
        |> Enum.sort()

      assert slugs == ["about", "faq"]
    end
  end
end
