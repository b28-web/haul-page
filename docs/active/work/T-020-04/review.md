# T-020-04 Review: Cost Tracking

## Summary of Changes

### New Files
| File | Purpose |
|------|---------|
| `lib/haul/ai/cost_tracker.ex` | Central cost tracking module — recording, estimation, aggregation, telemetry, alerts |
| `lib/haul/ai/cost_entry.ex` | Ash resource for `ai_cost_entries` table |
| `priv/repo/migrations/20260309155918_create_ai_cost_entries.exs` | DB migration with indexes |
| `test/haul/ai/cost_tracker_test.exs` | 24 unit/integration tests |
| `docs/active/work/T-020-04/{research,design,structure,plan,progress}.md` | RDSPI artifacts |

### Modified Files
| File | Change |
|------|--------|
| `lib/haul/ai/domain.ex` | Added CostEntry to Ash domain resources |
| `lib/haul/ai.ex` | Wrapped `call_function/3` to record BAML call costs |
| `lib/haul/ai/chat/anthropic.ex` | SSE usage capture (message_start, message_delta events) |
| `lib/haul_web/live/chat_live.ex` | Handle `{:ai_usage, usage}` to record chat costs |
| `lib/haul_web/telemetry.ex` | Added AI cost metrics (cost_usd, input_tokens, output_tokens) |
| `config/config.exs` | Added session/monthly alert threshold defaults |

## Acceptance Criteria Check

| Criterion | Status | Notes |
|-----------|--------|-------|
| CostTracker module | ✅ | `Haul.AI.CostTracker` |
| Logs every BAML function call | ✅ | Via `Haul.AI.call_function/3` wrapper |
| Function name, model, tokens, cost | ✅ | All fields on CostEntry |
| Per-session aggregation | ✅ | `session_total/1` linked via conversation_id |
| Platform-wide daily/monthly totals | ✅ | `daily_total/1`, `monthly_total/2` |
| Published per-token pricing (configurable) | ✅ | `@default_pricing` map, overridable via `:ai_pricing` config |
| Dashboard query: avg cost, trend | ✅ | `average_session_cost/0`, `daily_total/1` for trends |
| Session alert >$0.50 | ✅ | Logger.warning on threshold breach |
| Monthly budget alert | ✅ | Logger.error on threshold breach |
| Model selection strategy documented | ✅ | In research.md and function_models mapping |
| Telemetry events | ✅ | `[:haul, :ai, :call]` with token/cost metadata |

## Test Coverage

- **24 new tests** covering:
  - Token estimation (3 tests)
  - Cost calculation for Sonnet, Haiku, unknown model (3 tests)
  - Model-to-function mapping (3 tests)
  - `record_call` — creation, conversation linking, telemetry emission (3 tests)
  - `record_baml_call` — token estimation, conversation linking (2 tests)
  - `session_total` — summation, zero case, cross-session isolation (3 tests)
  - `daily_total` — today, empty date (2 tests)
  - `monthly_total` — current month (1 test)
  - `average_session_cost` — multi-session average, empty case (2 tests)
  - `pricing/0` — returns configured map (1 test)
  - Threshold alerts — session cost warning (1 test)
- **All 67 AI-related tests pass** (24 new + 43 existing)
- Existing tests unaffected — cost tracking is non-fatal (try/rescue)

## Design Decisions

1. **Token estimation for BAML calls**: ~4 chars/token heuristic since baml_elixir NIF doesn't expose API usage data. Acceptable because BAML uses Haiku (cheap). Chat path (Sonnet, expensive) gets exact counts from SSE events.

2. **Non-fatal recording**: `try/rescue` around DB writes. Tests without DataCase (no DB connection) get silently skipped cost recording. Production callers never crash due to cost tracking failures.

3. **Ash read actions for aggregation**: Defined `:for_conversation`, `:for_date_range`, `:with_conversation` on CostEntry. The `expr` macro doesn't work in regular module functions, so proper Ash read actions with filter clauses were needed.

4. **Usage capture via SSE events**: The Anthropic streaming API sends `message_start` (input_tokens) and `message_delta` (output_tokens). These are captured via an Agent and forwarded as `{:ai_usage, usage}` message on `message_stop`.

## Open Concerns

1. **Token estimation accuracy**: The 4-chars-per-token heuristic is approximate. For BAML calls this is fine (used for cost monitoring, not billing). If exact BAML token counts are needed later, would require either forking baml_elixir or switching to direct API calls.

2. **Aggregation at scale**: `sum_costs/1` reads all entries into memory before reducing. For production with thousands of entries, should add SQL-level aggregation via Ash calculations or raw Ecto queries. Current approach is fine for early stage.

3. **Monthly threshold check runs on every record**: Each `record_call` queries the full month's cost. Could be expensive at high volume. Consider caching the monthly total or checking less frequently (e.g., via Oban periodic job).

4. **No admin UI**: Dashboard queries exist but there's no admin page to visualize cost data. The data is available for `mix` tasks or future admin panel integration.

5. **Concurrent agent interference**: During implementation, other concurrent lisa agents kept reverting changes to tracked files. All changes were committed atomically after a batch apply.
