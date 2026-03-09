defmodule Haul.AI.CostTracker do
  @moduledoc """
  Tracks LLM token usage and cost per AI call.

  Logs every call with function name, model, tokens, and estimated cost.
  Aggregates per-session (linked to Conversation) and platform-wide totals.
  Emits telemetry events and checks alert thresholds.

  All recording operations are non-fatal — if persistence fails,
  the caller's operation is unaffected.
  """

  alias Haul.AI.CostEntry

  require Logger

  # Per-million-token pricing (USD)
  @default_pricing %{
    "claude-sonnet-4-20250514" => %{input: 3.0, output: 15.0},
    "claude-haiku-4-5-20251001" => %{input: 0.8, output: 4.0}
  }

  # BAML function -> model mapping (mirrors baml/main.baml client assignments)
  @function_models %{
    "ExtractOperatorProfile" => "claude-sonnet-4-20250514",
    "ExtractName" => "claude-sonnet-4-20250514",
    "GenerateServiceDescriptions" => "claude-haiku-4-5-20251001",
    "GenerateTagline" => "claude-haiku-4-5-20251001",
    "GenerateWhyHireUs" => "claude-haiku-4-5-20251001",
    "GenerateMetaDescription" => "claude-haiku-4-5-20251001"
  }

  @doc """
  Record an AI call with cost tracking. Non-fatal.
  """
  def record_call(params) do
    cost = estimate_cost(params.model, params.input_tokens, params.output_tokens)

    attrs = %{
      function_name: params.function_name,
      model: params.model,
      input_tokens: params.input_tokens,
      output_tokens: params.output_tokens,
      estimated_cost_usd: cost,
      conversation_id: Map.get(params, :conversation_id)
    }

    try do
      result =
        CostEntry
        |> Ash.Changeset.for_create(:record, attrs)
        |> Ash.create()

      case result do
        {:ok, entry} ->
          emit_telemetry(entry)
          check_thresholds(entry)
          {:ok, entry}

        {:error, reason} ->
          Logger.warning("[CostTracker] Failed to record: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.warning("[CostTracker] Failed to record (rescued): #{Exception.message(e)}")
        {:error, :recording_failed}
    end
  end

  @doc """
  Record a BAML function call with estimated tokens. Non-fatal.
  """
  def record_baml_call(function_name, args, result, opts \\ []) do
    model = model_for_function(function_name)
    input_text = Jason.encode!(args)
    output_text = Jason.encode!(result)

    record_call(%{
      function_name: function_name,
      model: model,
      input_tokens: estimate_tokens(input_text),
      output_tokens: estimate_tokens(output_text),
      conversation_id: Keyword.get(opts, :conversation_id)
    })
  end

  @doc """
  Estimate token count from text. ~4 characters per token for English.
  """
  def estimate_tokens(text) when is_binary(text) do
    max(1, div(String.length(text), 4))
  end

  def estimate_tokens(_), do: 1

  @doc """
  Calculate cost in USD for given model and token counts.
  """
  def estimate_cost(model, input_tokens, output_tokens) do
    rates = Map.get(pricing(), model, %{input: 3.0, output: 15.0})

    input_cost =
      Decimal.mult(
        Decimal.new("#{input_tokens}"),
        Decimal.div(Decimal.new("#{rates.input}"), Decimal.new("1000000"))
      )

    output_cost =
      Decimal.mult(
        Decimal.new("#{output_tokens}"),
        Decimal.div(Decimal.new("#{rates.output}"), Decimal.new("1000000"))
      )

    Decimal.add(input_cost, output_cost)
  end

  @doc """
  Return the model used by a BAML function name.
  """
  def model_for_function(function_name) do
    Map.get(@function_models, function_name, "claude-sonnet-4-20250514")
  end

  @doc """
  Return the current pricing map (configurable via application env).
  """
  def pricing do
    Application.get_env(:haul, :ai_pricing, @default_pricing)
  end

  @doc """
  Total estimated cost for a conversation session.
  """
  def session_total(conversation_id) do
    CostEntry
    |> Ash.Query.for_read(:for_conversation, %{conversation_id: conversation_id})
    |> Ash.read!()
    |> sum_costs()
  end

  @doc """
  Total estimated cost for a given date (UTC).
  """
  def daily_total(%Date{} = date) do
    start_dt = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    end_dt = DateTime.new!(Date.add(date, 1), ~T[00:00:00], "Etc/UTC")

    CostEntry
    |> Ash.Query.for_read(:for_date_range, %{start_at: start_dt, end_at: end_dt})
    |> Ash.read!()
    |> sum_costs()
  end

  @doc """
  Total estimated cost for a given year/month.
  """
  def monthly_total(year, month) do
    start_date = Date.new!(year, month, 1)
    end_date = Date.add(start_date, Date.days_in_month(start_date))

    start_dt = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_dt = DateTime.new!(end_date, ~T[00:00:00], "Etc/UTC")

    CostEntry
    |> Ash.Query.for_read(:for_date_range, %{start_at: start_dt, end_at: end_dt})
    |> Ash.read!()
    |> sum_costs()
  end

  @doc """
  Average cost per onboarding session across all conversations with cost entries.
  """
  def average_session_cost do
    entries =
      CostEntry
      |> Ash.Query.for_read(:with_conversation, %{})
      |> Ash.read!()

    by_session =
      entries
      |> Enum.group_by(& &1.conversation_id)
      |> Enum.map(fn {_id, session_entries} -> sum_costs(session_entries) end)

    case by_session do
      [] ->
        Decimal.new("0")

      totals ->
        sum = Enum.reduce(totals, Decimal.new("0"), &Decimal.add/2)
        Decimal.div(sum, Decimal.new("#{length(totals)}"))
    end
  end

  defp sum_costs(entries) do
    Enum.reduce(entries, Decimal.new("0"), fn entry, acc ->
      Decimal.add(acc, entry.estimated_cost_usd)
    end)
  end

  defp emit_telemetry(entry) do
    :telemetry.execute(
      [:haul, :ai, :call],
      %{
        input_tokens: entry.input_tokens,
        output_tokens: entry.output_tokens,
        estimated_cost_usd: Decimal.to_float(entry.estimated_cost_usd)
      },
      %{
        function_name: entry.function_name,
        model: entry.model,
        conversation_id: entry.conversation_id
      }
    )
  end

  defp check_thresholds(entry) do
    if entry.conversation_id do
      check_session_threshold(entry.conversation_id)
    end

    check_monthly_threshold()
  end

  defp check_session_threshold(conversation_id) do
    threshold =
      Application.get_env(:haul, :ai_session_cost_alert, 0.50)
      |> to_string()
      |> Decimal.new()

    total = session_total(conversation_id)

    if Decimal.compare(total, threshold) == :gt do
      Logger.warning(
        "[CostTracker] Session #{conversation_id} cost $#{Decimal.round(total, 4)} exceeds threshold $#{threshold}"
      )
    end
  end

  defp check_monthly_threshold do
    threshold = Application.get_env(:haul, :ai_monthly_budget_alert, 100.0)
    today = Date.utc_today()
    total = monthly_total(today.year, today.month)

    threshold_dec = threshold |> to_string() |> Decimal.new()

    if Decimal.compare(total, threshold_dec) == :gt do
      Logger.error(
        "[CostTracker] Monthly AI cost $#{Decimal.round(total, 2)} exceeds budget $#{threshold_dec}"
      )
    end
  end
end
