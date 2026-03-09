# T-020-04 Progress: Cost Tracking

## Completed Steps

### Step 1: CostEntry Ash Resource + Migration ✓
- Created `lib/haul/ai/cost_entry.ex` — Ash resource with uuid PK, conversation_id, function_name, model, input_tokens, output_tokens, estimated_cost_usd, inserted_at
- Read actions: `:for_conversation`, `:for_date_range`, `:with_conversation`
- Migration `20260309155918_create_ai_cost_entries.exs` with indexes on conversation_id and inserted_at
- Added to `Haul.AI.Domain` resources

### Step 2: CostTracker Module ✓
- Created `lib/haul/ai/cost_tracker.ex`
- `record_call/1` — creates CostEntry, emits telemetry, checks thresholds (non-fatal via try/rescue)
- `record_baml_call/4` — estimates tokens from serialized JSON, delegates to record_call
- `estimate_tokens/1` — ~4 chars/token heuristic
- `estimate_cost/3` — Decimal math with per-model pricing
- `model_for_function/1` — maps BAML function names to models
- `pricing/0` — configurable via `:ai_pricing` app env
- `session_total/1`, `daily_total/1`, `monthly_total/2`, `average_session_cost/0`

### Step 3: BAML Call Integration ✓
- Modified `Haul.AI.call_function/3` to accept opts and call `CostTracker.record_baml_call` after success
- Non-fatal: if cost recording fails, the original call result is still returned

### Step 4: Chat SSE Usage Capture ✓
- Modified `Haul.AI.Chat.Anthropic.stream_response/2`:
  - Added `usage_agent` to track token counts across SSE events
  - Captures `message_start` → input_tokens
  - Captures `message_delta` → output_tokens
  - Sends `{:ai_usage, %{input_tokens, output_tokens, model}}` to caller on `message_stop`

### Step 5: ChatLive Integration ✓
- Added `handle_info({:ai_usage, usage}, socket)` handler
- Records chat cost entry linked to conversation

### Step 6: Telemetry Metrics ✓
- Added AI metrics to `HaulWeb.Telemetry.metrics/0`:
  - `sum("haul.ai.call.estimated_cost_usd")`
  - `sum("haul.ai.call.input_tokens")`
  - `sum("haul.ai.call.output_tokens")`

### Step 7: Config ✓
- Added `:ai_session_cost_alert` (default 0.50) and `:ai_monthly_budget_alert` (default 100.0) to config.exs

### Step 8-9: Tests ✓
- 24 new tests in `test/haul/ai/cost_tracker_test.exs`
- All tests: estimate_tokens, estimate_cost, model_for_function, record_call, record_baml_call, session_total, daily_total, monthly_total, average_session_cost, pricing, telemetry emission, threshold alerts
- All 67 AI-related tests pass (24 new + 43 existing)

## Deviations from Plan
- Made cost tracking non-fatal with try/rescue — tests that don't use DataCase (no DB connection) now work without modification
- Used Ash read actions on CostEntry instead of inline Ash.Query.filter() — the expr macro doesn't work properly outside resource definitions
