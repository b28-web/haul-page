defmodule Haul.Content.Markdown do
  @moduledoc """
  Pure markdown and frontmatter utilities.

  Consolidates markdown rendering (from Page resource) and frontmatter parsing
  (from Seeder and AI.Prompt) into a single module.
  """

  @doc """
  Renders markdown to HTML with common extensions enabled.

  Uses MDEx with table, footnotes, and strikethrough extensions.
  """
  @spec render_html(String.t()) :: String.t()
  def render_html(markdown) when is_binary(markdown) do
    MDEx.to_html!(markdown, extension: [table: true, footnotes: true, strikethrough: true])
  end

  @doc """
  Parses YAML frontmatter from a markdown string.

  Returns `{frontmatter_map, body_string}`. Raises on invalid format.
  """
  @spec parse_frontmatter!(String.t()) :: {map(), String.t()}
  def parse_frontmatter!(content) when is_binary(content) do
    case Regex.run(~r/\A---\n(.+?)\n---\n(.*)\z/s, content) do
      [_, yaml, body] ->
        {YamlElixir.read_from_string!(yaml), String.trim(body)}

      nil ->
        raise "Invalid frontmatter format — expected ---\\n...\\n---\\n"
    end
  end

  @doc """
  Strips YAML frontmatter from a markdown string, returning only the body.
  """
  @spec strip_frontmatter(String.t()) :: String.t()
  def strip_frontmatter(content) when is_binary(content) do
    case Regex.run(~r/\A---\n.*?\n---\n(.*)\z/s, content) do
      [_, body] -> String.trim(body)
      nil -> String.trim(content)
    end
  end

  @doc """
  Extracts the version string from YAML frontmatter.

  Returns `{:ok, version}` or `{:error, :no_version | :no_frontmatter}`.
  """
  @spec parse_version(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def parse_version(content) when is_binary(content) do
    case Regex.run(~r/\A---\n(.*?)\n---/s, content) do
      [_, frontmatter] ->
        case Regex.run(~r/version:\s*(.+)/, frontmatter) do
          [_, version] -> {:ok, String.trim(version)}
          nil -> {:error, :no_version}
        end

      nil ->
        {:error, :no_frontmatter}
    end
  end
end
