defmodule Haul.AI.Prompt do
  @moduledoc """
  Loads prompt files from priv/prompts/ at runtime.
  """

  @doc """
  Load a prompt by name, returning the content with frontmatter stripped.

  The prompt file is read from `priv/prompts/{name}.md`.
  """
  @spec load(String.t()) :: {:ok, String.t()} | {:error, term()}
  def load(name) do
    case read_file(name) do
      {:ok, raw} -> {:ok, strip_frontmatter(raw)}
      error -> error
    end
  end

  @doc """
  Extract the version string from a prompt's YAML frontmatter.
  """
  @spec version(String.t()) :: {:ok, String.t()} | {:error, term()}
  def version(name) do
    case read_file(name) do
      {:ok, raw} -> parse_version(raw)
      error -> error
    end
  end

  defp read_file(name) do
    path = prompts_dir() |> Path.join("#{name}.md")

    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, {:file_error, reason, path}}
    end
  end

  defp prompts_dir do
    Application.app_dir(:haul, "priv/prompts")
  rescue
    # Fallback for dev/test when app is not started as a release
    ArgumentError -> Path.join(File.cwd!(), "priv/prompts")
  end

  defp strip_frontmatter(content) do
    case Regex.run(~r/\A---\n.*?\n---\n(.*)\z/s, content) do
      [_, body] -> String.trim(body)
      nil -> String.trim(content)
    end
  end

  defp parse_version(content) do
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
