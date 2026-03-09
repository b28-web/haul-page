defmodule Haul.AI.IntegrationTest do
  @moduledoc """
  Live BAML integration tests. Require a real LLM API key.

  Run with: BAML_LIVE_TESTS=1 mix test --include baml_live
  """
  use ExUnit.Case, async: false

  require Logger

  @moduletag :baml_live

  alias Haul.AI.OperatorProfile

  @test_transcript """
  Hi, I'm Dave Wilson. I run a junk removal company called Dave's Hauling
  in the Austin, Texas area. We've been around for 5 years. Our phone is
  512-555-0100 and email is dave@daveshauling.com. We mainly do junk removal,
  appliance pickup, and yard waste. Our motto is "Gone in 60 minutes!"
  """

  describe "live extraction" do
    test "extracts profile from real LLM call" do
      start = System.monotonic_time(:millisecond)

      result =
        Haul.AI.Baml.call_function("ExtractOperatorProfile", %{
          "transcript" => @test_transcript
        })

      elapsed = System.monotonic_time(:millisecond) - start

      assert {:ok, raw} = result
      assert is_map(raw)
      assert is_binary(raw["business_name"])
      assert String.length(raw["business_name"]) > 0

      profile = OperatorProfile.from_baml(raw)
      assert %OperatorProfile{} = profile
      assert profile.business_name != nil
      assert length(profile.services) > 0

      Logger.info("Extraction latency: #{elapsed}ms")
      Logger.info("Business name: #{profile.business_name}")
      Logger.info("Services: #{length(profile.services)}")
      Logger.info("Differentiators: #{length(profile.differentiators)}")
    end
  end
end
