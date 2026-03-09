# T-020-04 Plan: Cost Tracking

## Step 1: CostEntry Ash Resource + Migration

Create `lib/haul/ai/cost_entry.ex` with Ash resource definition. Create migration for `ai_cost_entries` table. Add to `Haul.AI.Domain` resources.

**Verify:** `mix ash.codegen` generates migration, `mix ecto.migrate` succeeds.

## Step 2: CostTracker Module

Create `lib/haul/ai/cost_tracker.ex` with:
- `record_call/1` — validates params, creates CostEntry, emits telemetry, checks thresholds
- `estimate_tokens/1` — `max(1, div(String.length(text), 4))`
- `estimate_cost/3` — pricing lookup × token counts
- `pricing/0` — returns configured or default pricing map
- Function-to-model mapping
- Session/daily/monthly aggregation queries (delegating to CostEntry read actions)
- Threshold checking with Logger.warning/error

**Verify:** Unit tests for estimation, cost calculation, pricing.

## Step 3: Integrate with Haul.AI (BAML Path)

Modify `Haul.AI.call_function/2` to accept optional `opts` keyword with `conversation_id`. After successful adapter call, estimate tokens from serialized args + result, call `CostTracker.record_call/1`.

**Verify:** Existing AI tests still pass. New test confirms cost entry created on call.

## Step 4: Capture Chat Usage from SSE

Modify `Haul.AI.Chat.Anthropic`:
- In `stream_response/2`, capture `message_start` event → extract `message.usage.input_tokens`
- Capture `message_delta` event → extract `usage.output_tokens`
- After stream completes, send `{:ai_usage, %{input_tokens: n, output_tokens: n, model: m}}` to pid

**Verify:** Parse test for new SSE event types. Existing streaming tests still pass.

## Step 5: ChatLive Integration

In `ChatLive`:
- Handle `{:ai_usage, usage}` info message
- Call `CostTracker.record_call/1` with conversation_id, "chat", model, exact token counts

**Verify:** ChatLive test with sandbox still works (no usage message sent by sandbox, no crash).

## Step 6: Telemetry Metrics

Add AI metrics to `HaulWeb.Telemetry.metrics/0`:
- `sum("haul.ai.call.estimated_cost_usd")`
- `sum("haul.ai.call.input_tokens")`
- `sum("haul.ai.call.output_tokens")`

**Verify:** App starts without errors.

## Step 7: Config + Alert Thresholds

Add to `config/config.exs`:
- `:ai_session_cost_alert` default 0.50
- `:ai_monthly_budget_alert` default 100.0

CostTracker checks these after each `record_call` and logs warnings.

**Verify:** Test that Logger.warning is emitted when threshold exceeded.

## Step 8: Aggregation Query Tests

Test CostTracker aggregation functions:
- `session_total/1` with multiple entries for one conversation
- `daily_total/1` for a specific date
- `monthly_total/2` for a year/month
- `average_session_cost/0`

**Verify:** All queries return correct sums.

## Step 9: Full Integration Test

End-to-end test: sandbox AI call → cost entry persisted → telemetry emitted → session total correct.

**Verify:** `mix test` all green. Run full suite.

## Testing Strategy
- **Unit tests**: Token estimation, cost calculation, pricing map, model mapping
- **Integration tests**: CostEntry creation via CostTracker, aggregation queries
- **Telemetry tests**: Attach handler, verify events emitted with correct measurements/metadata
- **Threshold tests**: Mock high costs, verify Logger warnings
- **Regression**: All existing AI tests pass unchanged
