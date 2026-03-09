# T-018-03 Plan: Extraction Function

## Step 1: Extend Sandbox with fixture overrides

**File:** `lib/haul/ai/sandbox.ex`

Add `set_response/2` and modify `call_function/2` to check Process dictionary first:
- `set_response(function_name, response)` — `Process.put({__MODULE__, function_name}, response)`
- At top of `call_function/2`, check `Process.get({__MODULE__, function_name})` before pattern matching

**Verify:** Existing AI tests still pass (`mix test test/haul/ai_test.exs test/haul/ai/operator_profile_test.exs test/haul/ai/profile_mapper_test.exs`)

## Step 2: Add BAML ExtractOperatorProfile function

**File:** `baml/main.baml`

Add function definition with extraction prompt. Key prompt elements:
- Extract all business information from the onboarding conversation
- Infer ServiceCategory from service descriptions
- Leave unknown fields as null
- Handle multi-message transcripts

**Verify:** BAML source file is syntactically valid (no runtime check needed — baml_elixir compiles at call time)

## Step 3: Create Extractor module

**File:** `lib/haul/ai/extractor.ex`

Implement:
- `extract_profile/1` — orchestrate call → parse → return
- Retry logic for transient errors
- `validate_completeness/1` — delegate to ProfileMapper + add service_area and services checks

**Verify:** Module compiles (`mix compile`)

## Step 4: Create Extractor tests

**File:** `test/haul/ai/extractor_test.exs`

Write test fixtures and cases:
1. Complete conversation → full profile extraction
2. Multi-message conversation → scattered info assembled
3. Ambiguous services → category inference
4. Partial info → profile with nils
5. Irrelevant content → business info extracted
6. API error handling → {:error, reason} returned
7. Transient error → retry succeeds
8. validate_completeness with complete profile → []
9. validate_completeness with missing fields → lists them
10. validate_completeness with no services → includes :services

Each test uses `Sandbox.set_response/2` to control the fixture.

**Verify:** All tests pass (`mix test test/haul/ai/extractor_test.exs`)

## Step 5: Full test suite verification

Run `mix test` to confirm no regressions.

## Testing Strategy

- **Unit tests** for Extractor module (extract_profile, validate_completeness, retry logic)
- **No integration tests** — adapter pattern isolates from real LLM calls
- **Fixture-based** — all test data inline, deterministic, no external files
- **Process-scoped** — Sandbox overrides are test-process-local via Process dictionary
