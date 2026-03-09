# T-018-03 Research: Extraction Function

## Existing Infrastructure

### BAML Layer (`baml/main.baml`)
- Anthropic client configured: `claude-sonnet-4-20250514`, API key from env
- Types defined: `OperatorProfile`, `ServiceOffering`, `ServiceCategory` (enum)
- Only function: `ExtractName` (demo) — no extraction function yet
- OperatorProfile fields: business_name, owner_name, phone, email, service_area, tagline?, years_in_business?, services[], differentiators[]

### Elixir AI Module (`lib/haul/ai/`)
- **`Haul.AI`** — behaviour + delegator to configured adapter
  - `call_function/2` callback: `(String.t(), map()) -> {:ok, map()} | {:error, any()}`
- **`Haul.AI.Baml`** — production adapter, calls `BamlElixir.Client.call/2`
- **`Haul.AI.Sandbox`** — dev/test adapter with fixture responses
  - Already has `"ExtractOperatorProfile"` fixture returning full profile map
- **`Haul.AI.OperatorProfile`** — struct + `from_baml/1` parser
  - Handles string→atom category conversion, nil defaults, nested ServiceOffering
- **`Haul.AI.ProfileMapper`** — pure transforms to Ash-ready maps
  - `missing_fields/1` already exists — returns list of nil required fields (business_name, phone, email)

### Test Coverage
- `test/haul/ai_test.exs` — smoke test for adapter delegation (2 tests)
- `test/haul/ai/operator_profile_test.exs` — struct parsing, categories (6 tests)
- `test/haul/ai/profile_mapper_test.exs` — mapper functions + missing fields (7 tests)

## What Needs Building

### 1. BAML Function Definition
The `ExtractOperatorProfile` function is referenced in Sandbox but not defined in `baml/main.baml`. Need:
- Function signature: `(transcript: string) -> OperatorProfile`
- Prompt: extract business info from conversation, infer ServiceCategory, null unknowns

### 2. Elixir Extractor Module (`Haul.AI.Extractor`)
Ticket requires a higher-level wrapper around `Haul.AI.call_function/2`:
- `extract_profile/1` — accepts transcript string, returns `{:ok, %OperatorProfile{}} | {:error, reason}`
- Error handling: LLM API errors, timeouts, rate limits
- Retry once on transient failure
- `validate_completeness/1` — takes OperatorProfile, returns missing required fields list

### 3. Test Fixtures
Need 5+ sample conversations covering:
- Complete info in one message
- Info spread across multiple messages
- Ambiguous service descriptions needing category inference
- Missing required fields (partial extraction)
- Irrelevant conversation mixed with business info

### 4. Recorded Response Testing
Tests must use recorded LLM responses, not live calls. The Sandbox adapter already provides this pattern — fixture responses keyed by function name.

## Key Observations

1. **`validate_completeness/1` overlaps with `ProfileMapper.missing_fields/1`** — both check for nil required fields. The Extractor version should delegate to or mirror ProfileMapper, not duplicate logic.

2. **Sandbox already handles the happy path** — `"ExtractOperatorProfile"` returns a full profile. For testing different scenarios (partial, ambiguous, etc.), we need the Sandbox to support multiple fixture variants, or we test at the Extractor level by mocking/controlling the AI call.

3. **Retry logic is new** — nothing in the current AI module retries. The Extractor wrapper is where this belongs (not in the adapter).

4. **BAML function naming** — Sandbox uses `"ExtractOperatorProfile"`, so the BAML function should match: `ExtractOperatorProfile`.

5. **Error classification** — need to distinguish transient errors (timeout, rate limit, network) from permanent errors (invalid input, parse failure) for retry decisions.

## Constraints

- No live API calls in tests (CI reliability)
- Config-driven adapter pattern must be preserved
- BAML function must use existing types from `main.baml`
- Extractor should compose existing modules (OperatorProfile.from_baml, ProfileMapper.missing_fields)
