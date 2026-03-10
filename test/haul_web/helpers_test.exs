defmodule HaulWeb.HelpersTest do
  use ExUnit.Case, async: true

  alias HaulWeb.Helpers

  describe "get_field/2" do
    test "reads from struct" do
      struct = %URI{host: "example.com"}
      assert Helpers.get_field(struct, :host) == "example.com"
    end

    test "reads from map with atom keys" do
      map = %{phone: "555-1234"}
      assert Helpers.get_field(map, :phone) == "555-1234"
    end

    test "reads from map with string keys" do
      map = %{"name" => "Bob"}
      assert Helpers.get_field(map, "name") == "Bob"
    end

    test "returns nil for missing field on struct" do
      struct = %URI{}
      assert Helpers.get_field(struct, :host) == nil
    end

    test "returns nil for missing key on map" do
      map = %{}
      assert Helpers.get_field(map, :missing) == nil
    end
  end

  describe "friendly_upload_error/1" do
    test "too_large" do
      assert Helpers.friendly_upload_error(:too_large) == "File is too large"
    end

    test "not_accepted" do
      assert Helpers.friendly_upload_error(:not_accepted) == "File type not supported"
    end

    test "too_many_files" do
      assert Helpers.friendly_upload_error(:too_many_files) == "Too many files"
    end

    test "unknown error converts to string" do
      assert Helpers.friendly_upload_error(:something_else) == "something_else"
    end
  end

  describe "merge_preferred_dates/1" do
    test "collapses date fields into list" do
      params = %{
        "preferred_date_1" => "2026-03-10",
        "preferred_date_2" => "2026-03-11",
        "preferred_date_3" => "",
        "other" => "value"
      }

      result = Helpers.merge_preferred_dates(params)

      assert result["preferred_dates"] == ["2026-03-10", "2026-03-11"]
      refute Map.has_key?(result, "preferred_date_1")
      refute Map.has_key?(result, "preferred_date_2")
      refute Map.has_key?(result, "preferred_date_3")
      assert result["other"] == "value"
    end

    test "returns empty list when no dates provided" do
      result = Helpers.merge_preferred_dates(%{})
      assert result["preferred_dates"] == []
    end

    test "filters nil values" do
      params = %{"preferred_date_1" => nil, "preferred_date_2" => "2026-03-10"}
      result = Helpers.merge_preferred_dates(params)
      assert result["preferred_dates"] == ["2026-03-10"]
    end
  end
end
