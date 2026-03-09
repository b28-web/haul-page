# T-020-04 Design: Cost Tracking

## Problem

Track LLM token usage and cost across two call paths (BAML + direct Anthropic API), aggregate per-session and platform-wide, emit telemetry, and alert on thresholds.

## Option A: Wrapper Module with Token Estimation (Chosen)

Wrap `Haul.AI.call_function/2` and `Haul.AI.Chat` to intercept calls, estimate tokens, compute cost, persist to DB, and emit telemetry.

**Token estimation for BAML calls:** Since baml_elixir doesn't expose usage data, estimate tokens from input/output text using a character-based heuristic (~4 chars per token for English). This is an approximation — good enough for cost tracking and alerting, not billing.

**Token capture for Chat calls:** Modify the SSE parser to capture `message_start` (input_tokens) and `message_delta` (output_tokens) events from the Anthropic streaming API. These provide exact counts.

**Pros:** Non-invasive, works with current baml_elixir, exact counts for chat (the expensive path).
**Cons:** BAML token counts are estimates. Acceptable because BAML calls use Haiku (cheap) and the chat path (Sonnet, expensive) gets exact counts.

## Option B: Custom HTTP Client for BAML (Rejected)

Inject a custom HTTP client into baml_elixir to capture raw API responses including usage. Rejected because baml_elixir uses a Rust NIF — no HTTP client injection point exists. Would require forking/patching the library.

## Option C: Telemetry-Only (No Persistence) (Rejected)

Emit telemetry events without persisting to DB. Rejected because the ticket requires per-session aggregation linked to Conversation, dashboard queries, and monthly budget tracking — all need persistence.

## Architecture

### CostTracker Module
`Haul.AI.CostTracker` — the central module. Responsibilities:
1. **Record a call**: Store function_name, model, input_tokens, output_tokens, cost_usd, linked to conversation_id
2. **Estimate cost**: Apply per-model pricing to token counts
3. **Emit telemetry**: `:telemetry.execute([:haul, :ai, :call], measurements, metadata)`
4. **Check thresholds**: Warn if session total > $0.50, warn if monthly total > budget

### Data Model
`Haul.AI.CostEntry` — Ash resource, public schema (not tenant-scoped, like Conversation).

Fields:
- `id` (uuid pk)
- `conversation_id` (uuid, FK to conversations, nullable for non-session calls)
- `function_name` (string) — "chat", "ExtractOperatorProfile", etc.
- `model` (string) — "claude-sonnet-4-20250514", "claude-haiku-4-5-20251001"
- `input_tokens` (integer)
- `output_tokens` (integer)
- `estimated_cost_usd` (decimal) — calculated at insert time
- `inserted_at` (timestamp)

Indexes: `[conversation_id]`, `[inserted_at]` (for daily/monthly queries)

### Token Estimation
```
~4 chars per token (English text average)
estimate_tokens(text) = max(1, div(String.length(text), 4))
```

For BAML: estimate from serialized input args (JSON) and serialized result (JSON).
For Chat: use exact counts from API response.

### Pricing Configuration
Module attribute map in CostTracker, overridable via application config:
```elixir
@default_pricing %{
  "claude-sonnet-4-20250514" => %{input: 3.0, output: 15.0},  # per 1M tokens
  "claude-haiku-4-5-20251001" => %{input: 0.8, output: 4.0}
}
```

### Model Mapping for BAML Functions
Since BAML functions don't report which model they used, maintain a mapping:
```elixir
@function_models %{
  "ExtractOperatorProfile" => "claude-sonnet-4-20250514",
  "ExtractName" => "claude-sonnet-4-20250514",
  "GenerateServiceDescriptions" => "claude-haiku-4-5-20251001",
  "GenerateTagline" => "claude-haiku-4-5-20251001",
  "GenerateWhyHireUs" => "claude-haiku-4-5-20251001",
  "GenerateMetaDescription" => "claude-haiku-4-5-20251001"
}
```

### Integration Points

1. **BAML calls**: Wrap `Haul.AI.call_function/2` — add a `track_call/2` that records before returning
2. **Chat streaming**: Capture usage from SSE events in `Anthropic` adapter, send `{:ai_usage, usage}` to caller
3. **ChatLive**: Handle `{:ai_usage, usage}` to record chat cost entries
4. **Telemetry**: Emit on every call record creation
5. **Alerts**: Logger.warning for session threshold, Logger.error for monthly budget

### Dashboard Queries
Read actions on CostEntry:
- `session_total` — sum cost for a conversation_id
- `daily_total` — sum cost for a date
- `monthly_total` — sum cost for a month
- `average_per_session` — avg session cost over a date range

### Sandbox Strategy
CostTracker works in test/dev with estimated tokens from Sandbox responses. No special sandbox adapter needed — the tracker wraps the call regardless of adapter.
