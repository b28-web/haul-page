defmodule Haul.Content.LoaderTest do
  use ExUnit.Case, async: true

  alias Haul.Content.Loader

  describe "gallery_items/0" do
    test "returns a non-empty list" do
      items = Loader.gallery_items()
      assert is_list(items)
      assert items != []
    end

    test "each item has required keys" do
      for item <- Loader.gallery_items() do
        assert Map.has_key?(item, :before_photo_url)
        assert Map.has_key?(item, :after_photo_url)
        assert is_binary(item.before_photo_url)
        assert is_binary(item.after_photo_url)
      end
    end

    test "caption is a string when present" do
      for item <- Loader.gallery_items() do
        if item[:caption], do: assert(is_binary(item.caption))
      end
    end
  end

  describe "endorsements/0" do
    test "returns a non-empty list" do
      items = Loader.endorsements()
      assert is_list(items)
      assert items != []
    end

    test "each item has required keys" do
      for item <- Loader.endorsements() do
        assert Map.has_key?(item, :customer_name)
        assert Map.has_key?(item, :quote_text)
        assert is_binary(item.customer_name)
        assert is_binary(item.quote_text)
      end
    end

    test "star_rating is an integer 1-5 when present" do
      for item <- Loader.endorsements() do
        if item[:star_rating] do
          assert is_integer(item.star_rating)
          assert item.star_rating >= 1 and item.star_rating <= 5
        end
      end
    end

    test "date is a string when present" do
      for item <- Loader.endorsements() do
        if item[:date], do: assert(is_binary(item.date))
      end
    end
  end
end
