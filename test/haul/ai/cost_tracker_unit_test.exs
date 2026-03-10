defmodule Haul.AI.CostTrackerUnitTest do
  use ExUnit.Case, async: true

  alias Haul.AI.CostTracker

  describe "estimate_tokens/1" do
    test "estimates ~4 chars per token" do
      assert CostTracker.estimate_tokens("hello world") == 2
      assert CostTracker.estimate_tokens("a") == 1
      assert CostTracker.estimate_tokens("") == 1
    end

    test "returns 1 for non-string input" do
      assert CostTracker.estimate_tokens(nil) == 1
      assert CostTracker.estimate_tokens(42) == 1
    end

    test "handles longer text" do
      text = String.duplicate("abcd", 100)
      assert CostTracker.estimate_tokens(text) == 100
    end
  end

  describe "estimate_cost/3" do
    test "calculates cost for Sonnet model" do
      cost = CostTracker.estimate_cost("claude-sonnet-4-20250514", 1000, 500)
      # Input: 1000 * 3.0/1M = 0.003, Output: 500 * 15.0/1M = 0.0075
      expected = Decimal.add(Decimal.new("0.003"), Decimal.new("0.0075"))
      assert Decimal.equal?(cost, expected)
    end

    test "calculates cost for Haiku model" do
      cost = CostTracker.estimate_cost("claude-haiku-4-5-20251001", 1000, 500)
      # Input: 1000 * 0.8/1M = 0.0008, Output: 500 * 4.0/1M = 0.002
      expected = Decimal.add(Decimal.new("0.0008"), Decimal.new("0.002"))
      assert Decimal.equal?(cost, expected)
    end

    test "uses default pricing for unknown model" do
      cost = CostTracker.estimate_cost("unknown-model", 1000, 500)
      # Falls back to Sonnet pricing
      assert Decimal.compare(cost, Decimal.new("0")) == :gt
    end
  end

  describe "model_for_function/1" do
    test "maps extraction functions to Sonnet" do
      assert CostTracker.model_for_function("ExtractOperatorProfile") ==
               "claude-sonnet-4-20250514"

      assert CostTracker.model_for_function("ExtractName") == "claude-sonnet-4-20250514"
    end

    test "maps generation functions to Haiku" do
      assert CostTracker.model_for_function("GenerateServiceDescriptions") ==
               "claude-haiku-4-5-20251001"

      assert CostTracker.model_for_function("GenerateTagline") == "claude-haiku-4-5-20251001"
      assert CostTracker.model_for_function("GenerateWhyHireUs") == "claude-haiku-4-5-20251001"

      assert CostTracker.model_for_function("GenerateMetaDescription") ==
               "claude-haiku-4-5-20251001"
    end

    test "defaults to Sonnet for unknown functions" do
      assert CostTracker.model_for_function("UnknownFunction") == "claude-sonnet-4-20250514"
    end
  end

  describe "pricing/0" do
    test "returns default pricing map" do
      pricing = CostTracker.pricing()
      assert Map.has_key?(pricing, "claude-sonnet-4-20250514")
      assert Map.has_key?(pricing, "claude-haiku-4-5-20251001")

      sonnet = pricing["claude-sonnet-4-20250514"]
      assert sonnet.input == 3.0
      assert sonnet.output == 15.0
    end
  end
end
