defmodule Haul.Admin.AccountHelpersTest do
  use ExUnit.Case, async: true

  alias Haul.Admin.AccountHelpers

  defp make_company(slug, name, inserted_at \\ ~U[2026-01-01 00:00:00Z]) do
    %{slug: slug, name: name, inserted_at: inserted_at}
  end

  describe "filter_companies/2" do
    test "empty term returns all" do
      companies = [make_company("a", "Alpha"), make_company("b", "Beta")]
      assert AccountHelpers.filter_companies(companies, "") == companies
    end

    test "filters by slug" do
      companies = [make_company("haulers", "Haulers Inc"), make_company("junk", "Junk Co")]
      result = AccountHelpers.filter_companies(companies, "haul")
      assert length(result) == 1
      assert hd(result).slug == "haulers"
    end

    test "filters by name case-insensitively" do
      companies = [make_company("a", "Big Haulers"), make_company("b", "Small Movers")]
      result = AccountHelpers.filter_companies(companies, "big")
      assert length(result) == 1
      assert hd(result).name == "Big Haulers"
    end

    test "matches partial slug or name" do
      companies = [make_company("abc", "XYZ Corp")]
      assert AccountHelpers.filter_companies(companies, "ab") == companies
      assert AccountHelpers.filter_companies(companies, "xyz") == companies
    end
  end

  describe "sort_companies/3" do
    test "sorts by name ascending" do
      companies = [make_company("b", "Beta"), make_company("a", "Alpha")]
      result = AccountHelpers.sort_companies(companies, :name, :asc)
      assert Enum.map(result, & &1.name) == ["Alpha", "Beta"]
    end

    test "sorts by name descending" do
      companies = [make_company("a", "Alpha"), make_company("b", "Beta")]
      result = AccountHelpers.sort_companies(companies, :name, :desc)
      assert Enum.map(result, & &1.name) == ["Beta", "Alpha"]
    end

    test "sorts by slug" do
      companies = [make_company("b", "B"), make_company("a", "A")]
      result = AccountHelpers.sort_companies(companies, :slug, :asc)
      assert Enum.map(result, & &1.slug) == ["a", "b"]
    end

    test "sorts by inserted_at" do
      c1 = make_company("a", "A", ~U[2026-01-01 00:00:00Z])
      c2 = make_company("b", "B", ~U[2026-02-01 00:00:00Z])
      result = AccountHelpers.sort_companies([c2, c1], :inserted_at, :asc)
      assert Enum.map(result, & &1.slug) == ["a", "b"]
    end

    test "unknown field returns list unchanged" do
      companies = [make_company("a", "A")]
      assert AccountHelpers.sort_companies(companies, :unknown, :asc) == companies
    end
  end

  describe "toggle_dir/1" do
    test "toggles asc to desc" do
      assert AccountHelpers.toggle_dir(:asc) == :desc
    end

    test "toggles desc to asc" do
      assert AccountHelpers.toggle_dir(:desc) == :asc
    end
  end

  describe "sort_indicator/3" do
    test "returns up arrow for current ascending" do
      assert AccountHelpers.sort_indicator(:name, :name, :asc) == "↑"
    end

    test "returns down arrow for current descending" do
      assert AccountHelpers.sort_indicator(:name, :name, :desc) == "↓"
    end

    test "returns empty for non-current field" do
      assert AccountHelpers.sort_indicator(:name, :slug, :asc) == ""
    end
  end
end
