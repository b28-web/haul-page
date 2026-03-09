# T-020-04 Research: Cost Tracking

## AI Call Sites (Two Paths)

### Path 1: BAML (structured extraction + content generation)
- `Haul.AI.call_function/2` → adapter dispatch → `Haul.AI.Baml.call_function/2`
- Uses `BamlElixir.Client.call/3` NIF — returns `{:ok, map} | {:error, any}`
- **No token/usage data exposed** by baml_elixir 0.2.0. Only the parsed result map.
- 6 BAML functions:
  - `ExtractOperatorProfile` — Sonnet 4 (extraction)
  - `ExtractName` — Sonnet 4 (extraction)
  - `GenerateServiceDescriptions` — Haiku 4.5 (content gen)
  - `GenerateTagline` — Haiku 4.5 (content gen)
  - `GenerateWhyHireUs` — Haiku 4.5 (content gen)
  - `GenerateMetaDescription` — Haiku 4.5 (content gen)
- Model assignment is in `baml/main.baml` — each function has a `client` field pointing to a model.

### Path 2: Direct Anthropic API (streaming chat)
- `Haul.AI.Chat.Anthropic.stream_message/3` — Req POST with SSE streaming
- Model: `claude-sonnet-4-20250514`, max_tokens: 1024
- SSE events parsed: `content_block_delta`, `message_stop`, `error`
- **`message_start` event (contains `usage.input_tokens`) is NOT captured** — falls through to `_ -> :ok`
- **`message_delta` event (contains `usage.output_tokens`) is NOT captured** either
- Non-streaming `send_message/2` also discards usage from response body

### Callers
- `Haul.AI.Extractor` — calls BAML `ExtractOperatorProfile` (with retry)
- `Haul.AI.ContentGenerator` — calls 4 BAML generation functions (with retry each)
- `Haul.AI.Provisioner` — orchestrates Extractor + ContentGenerator, tracks duration_ms
- `HaulWeb.ChatLive` — streams chat via `Chat.stream_message/3`, triggers extraction via Extractor

## Conversation Model
- `Haul.AI.Conversation` — Ash resource, public schema (not tenant-scoped)
- Fields: `id`, `session_id`, `messages` (array of maps), `extracted_profile`, `status`, `company_id`
- Status lifecycle: `:active` → `:provisioning` → `:completed` (or `:failed`/`:abandoned`)
- **No cost-related columns exist**

## Telemetry Infrastructure
- `HaulWeb.Telemetry` — supervisor with `:telemetry_poller` (10s)
- Existing metrics: Phoenix endpoint/router, Ecto repo queries, VM memory/queues
- **No AI/LLM telemetry events defined**
- No `:telemetry.execute/3` calls in any AI module

## Configuration Patterns
- Adapter pattern: `config :haul, :ai_adapter` / `config :haul, :chat_adapter`
- Sandbox adapters for dev/test, real adapters for prod
- API key: `config :haul, :anthropic_api_key` from `ANTHROPIC_API_KEY` env var
- Feature flag: `:chat_available` for graceful degradation

## Test Infrastructure
- Sandbox adapters use `Process.put/get` (BAML) and ETS (Chat) for fixture responses
- Tests exist for Extractor, ContentGenerator, integration flow
- No cost tracking in any tests

## Key Constraints
1. **baml_elixir NIF doesn't expose token counts** — must estimate from input/output text
2. **Chat streaming discards usage events** — needs SSE handler update to capture them
3. **No DB table for cost records** — need migration
4. **Conversation is the natural aggregation point** — already has session_id + company_id

## Pricing Reference (Anthropic, current)
| Model | Input $/1M tokens | Output $/1M tokens |
|-------|--------------------|--------------------|
| Claude Sonnet 4 | $3.00 | $15.00 |
| Claude Haiku 4.5 | $0.80 | $4.00 |

## Onboarding Session Cost Anatomy
A typical onboarding session involves:
1. ~5-15 chat messages (Sonnet streaming) — ~500-2000 input tokens/msg, ~100-300 output tokens/msg
2. 1 extraction call (Sonnet via BAML) — ~2000 input, ~500 output tokens
3. 4 content generation calls (Haiku via BAML) — ~500-1000 input, ~200-500 output each
4. Target: <$0.10 total per session

## Existing Patterns to Follow
- Ash resources for domain data (cost records)
- Adapter/behaviour pattern for swappable implementations
- Oban for async work (could use for budget alerts)
- Logger for warnings (session threshold alerts)
- `:telemetry.execute/3` for metrics emission
