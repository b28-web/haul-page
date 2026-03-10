defmodule Haul.FormattingTest do
  use ExUnit.Case, async: true

  alias Haul.Formatting

  describe "plan_rank/1" do
    test "returns correct ranks" do
      assert Formatting.plan_rank(:starter) == 0
      assert Formatting.plan_rank(:pro) == 1
      assert Formatting.plan_rank(:business) == 2
      assert Formatting.plan_rank(:dedicated) == 3
    end

    test "unknown plan returns 0" do
      assert Formatting.plan_rank(:unknown) == 0
    end
  end

  describe "plan_name/1" do
    test "returns display names" do
      assert Formatting.plan_name(:starter) == "Starter"
      assert Formatting.plan_name(:pro) == "Pro"
      assert Formatting.plan_name(:business) == "Business"
      assert Formatting.plan_name(:dedicated) == "Dedicated"
    end

    test "unknown plan returns Unknown" do
      assert Formatting.plan_name(:foo) == "Unknown"
    end
  end

  describe "format_price/1" do
    test "zero cents is Free" do
      assert Formatting.format_price(0) == "Free"
    end

    test "formats cents as monthly price" do
      assert Formatting.format_price(2900) == "$29/mo"
      assert Formatting.format_price(9900) == "$99/mo"
    end
  end

  describe "format_amount/1" do
    test "formats cents with decimal" do
      assert Formatting.format_amount(5000) == "$50.00"
      assert Formatting.format_amount(1299) == "$12.99"
      assert Formatting.format_amount(100) == "$1.00"
      assert Formatting.format_amount(5) == "$0.05"
    end
  end

  describe "days_until_downgrade/1" do
    test "returns remaining grace days" do
      two_days_ago = DateTime.add(DateTime.utc_now(), -2, :day)
      assert Formatting.days_until_downgrade(two_days_ago) == 5
    end

    test "returns 0 when grace period expired" do
      ten_days_ago = DateTime.add(DateTime.utc_now(), -10, :day)
      assert Formatting.days_until_downgrade(ten_days_ago) == 0
    end

    test "returns 7 when just started" do
      assert Formatting.days_until_downgrade(DateTime.utc_now()) == 7
    end
  end

  describe "plan_badge_class/1" do
    test "returns CSS classes for known plans" do
      assert Formatting.plan_badge_class(:starter) =~ "zinc"
      assert Formatting.plan_badge_class(:pro) =~ "blue"
      assert Formatting.plan_badge_class(:business) =~ "purple"
      assert Formatting.plan_badge_class(:dedicated) =~ "amber"
    end

    test "unknown plan returns default" do
      assert Formatting.plan_badge_class(:foo) =~ "zinc"
    end
  end

  describe "star_display/1" do
    test "nil returns nil" do
      assert Formatting.star_display(nil) == nil
    end

    test "renders stars" do
      assert Formatting.star_display(5) == "★★★★★"
      assert Formatting.star_display(3) == "★★★☆☆"
      assert Formatting.star_display(1) == "★☆☆☆☆"
      assert Formatting.star_display(0) == "☆☆☆☆☆"
    end
  end

  describe "source_label/1" do
    test "nil returns nil" do
      assert Formatting.source_label(nil) == nil
    end

    test "returns labels" do
      assert Formatting.source_label(:google) == "Google"
      assert Formatting.source_label(:yelp) == "Yelp"
      assert Formatting.source_label(:direct) == "Direct"
      assert Formatting.source_label(:facebook) == "Facebook"
    end
  end
end
