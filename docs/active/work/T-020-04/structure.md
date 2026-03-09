# T-020-04 Structure: Cost Tracking

## New Files

### `lib/haul/ai/cost_tracker.ex`
Central module. Public API:
- `record_call(params)` — insert CostEntry, emit telemetry, check thresholds
- `estimate_tokens(text)` — char-based token estimation
- `estimate_cost(model, input_tokens, output_tokens)` — apply pricing
- `session_total(conversation_id)` — sum cost_usd for session
- `daily_total(date)` — sum cost_usd for date
- `monthly_total(year, month)` — sum cost_usd for month
- `average_session_cost(opts)` — avg cost per session
- `pricing()` — return current pricing map

### `lib/haul/ai/cost_entry.ex`
Ash resource (public schema, no tenancy). Table: `ai_cost_entries`.
Attributes: id, conversation_id, function_name, model, input_tokens, output_tokens, estimated_cost_usd, inserted_at.
Actions: create `:record`, read `:for_conversation`, `:daily_summary`, `:monthly_summary`.

### `priv/repo/migrations/TIMESTAMP_create_ai_cost_entries.exs`
Create `ai_cost_entries` table with indexes on `conversation_id` and `inserted_at`.

### `test/haul/ai/cost_tracker_test.exs`
Tests for recording, estimation, aggregation, telemetry emission, threshold alerts.

## Modified Files

### `lib/haul/ai.ex`
Add cost tracking to `call_function/2`. After the adapter call succeeds, call `CostTracker.record_call/1` with estimated tokens. Accept optional `conversation_id` parameter.

### `lib/haul/ai/chat/anthropic.ex`
Capture `message_start` and `message_delta` SSE events to extract token usage. Send `{:ai_usage, %{input_tokens: n, output_tokens: n}}` to the caller pid.

### `lib/haul/ai/domain.ex`
Add `CostEntry` to the AI domain's resource list.

### `lib/haul_web/telemetry.ex`
Add AI cost metrics to `metrics/0`:
- `sum("haul.ai.call.cost_usd")` with tags `[:function_name, :model]`
- `sum("haul.ai.call.input_tokens")` with tags `[:function_name, :model]`
- `sum("haul.ai.call.output_tokens")` with tags `[:function_name, :model]`
- `summary("haul.ai.call.duration")` with tags `[:function_name]`

### `lib/haul_web/live/chat_live.ex`
Handle `{:ai_usage, usage}` message — call CostTracker.record_call with conversation_id and exact token counts.

### `config/config.exs`
Add default AI cost tracking config:
- `:ai_session_cost_alert` — threshold in USD (default 0.50)
- `:ai_monthly_budget_alert` — threshold in USD (default 100.0)

## Unchanged Files
- `lib/haul/ai/baml.ex` — no changes needed, wrapping happens in `Haul.AI`
- `lib/haul/ai/sandbox.ex` — unchanged, cost tracking works transparently
- `lib/haul/ai/chat/sandbox.ex` — unchanged, no usage data to capture
- `lib/haul/ai/conversation.ex` — unchanged, linked via conversation_id FK on cost_entry
- `lib/haul/ai/extractor.ex` — unchanged, uses `Haul.AI.call_function`
- `lib/haul/ai/content_generator.ex` — unchanged, uses `Haul.AI.call_function`

## Module Boundaries
- `CostTracker` depends on `CostEntry` (for persistence) and `:telemetry` (for events)
- `Haul.AI` depends on `CostTracker` (for recording after calls)
- `Chat.Anthropic` sends usage messages to caller (no direct CostTracker dependency)
- `ChatLive` depends on `CostTracker` (for recording chat usage)
- All aggregation queries go through `CostTracker` public API, not direct Ash reads
