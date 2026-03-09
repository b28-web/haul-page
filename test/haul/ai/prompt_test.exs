defmodule Haul.AI.PromptTest do
  use ExUnit.Case, async: true

  alias Haul.AI.Prompt

  describe "load/1" do
    test "loads prompt content without frontmatter" do
      assert {:ok, content} = Prompt.load("onboarding_agent")
      assert is_binary(content)
      refute content =~ ~r/\A---/
      refute content =~ "version: v1"
    end

    test "returns error for missing prompt" do
      assert {:error, {:file_error, :enoent, _path}} = Prompt.load("nonexistent")
    end
  end

  describe "version/1" do
    test "extracts version from frontmatter" do
      assert {:ok, "v1"} = Prompt.version("onboarding_agent")
    end

    test "returns error for missing prompt" do
      assert {:error, {:file_error, :enoent, _path}} = Prompt.version("nonexistent")
    end
  end
end
