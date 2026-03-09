defmodule Haul.AI.CostTrackerTest do
  use Haul.DataCase, async: true

  alias Haul.AI.CostTracker
  alias Haul.AI.Conversation

  defp create_conversation do
    Conversation
    |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
    |> Ash.create!()
  end

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

  describe "record_call/1" do
    test "creates a cost entry" do
      {:ok, entry} =
        CostTracker.record_call(%{
          function_name: "chat",
          model: "claude-sonnet-4-20250514",
          input_tokens: 500,
          output_tokens: 200
        })

      assert entry.function_name == "chat"
      assert entry.model == "claude-sonnet-4-20250514"
      assert entry.input_tokens == 500
      assert entry.output_tokens == 200
      assert Decimal.compare(entry.estimated_cost_usd, Decimal.new("0")) == :gt
    end

    test "links to conversation" do
      conv = create_conversation()

      {:ok, entry} =
        CostTracker.record_call(%{
          function_name: "ExtractOperatorProfile",
          model: "claude-sonnet-4-20250514",
          input_tokens: 1000,
          output_tokens: 300,
          conversation_id: conv.id
        })

      assert entry.conversation_id == conv.id
    end

    test "emits telemetry event" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:haul, :ai, :call]
        ])

      {:ok, _entry} =
        CostTracker.record_call(%{
          function_name: "chat",
          model: "claude-sonnet-4-20250514",
          input_tokens: 100,
          output_tokens: 50
        })

      assert_received {[:haul, :ai, :call], ^ref, measurements, metadata}
      assert measurements.input_tokens == 100
      assert measurements.output_tokens == 50
      assert is_float(measurements.estimated_cost_usd)
      assert metadata.function_name == "chat"
      assert metadata.model == "claude-sonnet-4-20250514"
    end
  end

  describe "record_baml_call/4" do
    test "estimates tokens from serialized args and result" do
      args = %{"transcript" => "user: Hello, I run a junk removal business"}
      result = %{"business_name" => "Test Hauling", "phone" => "555-0123"}

      {:ok, entry} = CostTracker.record_baml_call("ExtractOperatorProfile", args, result)

      assert entry.function_name == "ExtractOperatorProfile"
      assert entry.model == "claude-sonnet-4-20250514"
      assert entry.input_tokens > 0
      assert entry.output_tokens > 0
    end

    test "links to conversation when provided" do
      conv = create_conversation()
      args = %{"text" => "John Doe"}
      result = %{"first_name" => "John", "last_name" => "Doe"}

      {:ok, entry} =
        CostTracker.record_baml_call("ExtractName", args, result, conversation_id: conv.id)

      assert entry.conversation_id == conv.id
    end
  end

  describe "session_total/1" do
    test "sums costs for a conversation" do
      conv = create_conversation()

      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-sonnet-4-20250514",
        input_tokens: 1000,
        output_tokens: 200,
        conversation_id: conv.id
      })

      CostTracker.record_call(%{
        function_name: "ExtractOperatorProfile",
        model: "claude-sonnet-4-20250514",
        input_tokens: 2000,
        output_tokens: 500,
        conversation_id: conv.id
      })

      total = CostTracker.session_total(conv.id)
      assert Decimal.compare(total, Decimal.new("0")) == :gt
    end

    test "returns zero for conversation with no entries" do
      total = CostTracker.session_total(Ecto.UUID.generate())
      assert Decimal.equal?(total, Decimal.new("0"))
    end

    test "excludes entries from other conversations" do
      conv1 = create_conversation()
      conv2 = create_conversation()

      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-sonnet-4-20250514",
        input_tokens: 1000,
        output_tokens: 200,
        conversation_id: conv1.id
      })

      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-sonnet-4-20250514",
        input_tokens: 5000,
        output_tokens: 1000,
        conversation_id: conv2.id
      })

      total1 = CostTracker.session_total(conv1.id)
      total2 = CostTracker.session_total(conv2.id)

      assert Decimal.compare(total2, total1) == :gt
    end
  end

  describe "daily_total/1" do
    test "sums costs for today" do
      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-sonnet-4-20250514",
        input_tokens: 1000,
        output_tokens: 200
      })

      total = CostTracker.daily_total(Date.utc_today())
      assert Decimal.compare(total, Decimal.new("0")) == :gt
    end

    test "returns zero for date with no entries" do
      total = CostTracker.daily_total(~D[2020-01-01])
      assert Decimal.equal?(total, Decimal.new("0"))
    end
  end

  describe "monthly_total/2" do
    test "sums costs for current month" do
      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-haiku-4-5-20251001",
        input_tokens: 500,
        output_tokens: 100
      })

      today = Date.utc_today()
      total = CostTracker.monthly_total(today.year, today.month)
      assert Decimal.compare(total, Decimal.new("0")) == :gt
    end
  end

  describe "average_session_cost/0" do
    test "computes average across sessions" do
      conv1 = create_conversation()
      conv2 = create_conversation()

      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-sonnet-4-20250514",
        input_tokens: 1000,
        output_tokens: 200,
        conversation_id: conv1.id
      })

      CostTracker.record_call(%{
        function_name: "chat",
        model: "claude-sonnet-4-20250514",
        input_tokens: 1000,
        output_tokens: 200,
        conversation_id: conv2.id
      })

      avg = CostTracker.average_session_cost()
      assert Decimal.compare(avg, Decimal.new("0")) == :gt
    end

    test "returns zero when no entries exist" do
      assert Decimal.equal?(CostTracker.average_session_cost(), Decimal.new("0"))
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

  describe "threshold alerts" do
    import ExUnit.CaptureLog

    test "logs warning when session cost exceeds threshold" do
      conv = create_conversation()

      # Set a very low threshold
      Application.put_env(:haul, :ai_session_cost_alert, 0.0001)

      log =
        capture_log(fn ->
          CostTracker.record_call(%{
            function_name: "chat",
            model: "claude-sonnet-4-20250514",
            input_tokens: 10_000,
            output_tokens: 5000,
            conversation_id: conv.id
          })
        end)

      assert log =~ "[CostTracker] Session"
      assert log =~ "exceeds threshold"
    after
      Application.put_env(:haul, :ai_session_cost_alert, 0.50)
    end
  end
end
