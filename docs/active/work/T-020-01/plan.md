# T-020-01 Plan: Content Generation Functions

## Step 1: Add BAML types and functions to main.baml

Add AnthropicHaiku client, 4 output types, 4 generation functions.

Verify: `mix compile` passes (BAML source is parsed at runtime, but syntax should be valid).

## Step 2: Add sandbox responses

Add 4 new `default_response/2` clauses in `Haul.AI.Sandbox` for the new function names.

Verify: Existing tests still pass (`mix test test/haul/ai/`).

## Step 3: Create ContentGenerator module

Create `lib/haul/ai/content_generator.ex` with:
- 4 public generation functions + `generate_all/1`
- Each calls `Haul.AI.call_function/2` with appropriate args built from OperatorProfile
- Retry logic for transient errors
- Logger.info for completion tracking

Verify: Module compiles without errors.

## Step 4: Create ContentGenerator tests

Create `test/haul/ai/content_generator_test.exs` with:
- Tests for each generation function using sandbox defaults
- Tests for `generate_all/1` consolidated output
- Tests for error handling (sandbox override with error response)
- Tests for output structure validation (service count match, tagline count, bullet count, meta length)
- Tests using custom sandbox overrides

Verify: `mix test test/haul/ai/content_generator_test.exs` — all pass.

## Step 5: Run full test suite

Verify: `mix test` — no regressions.

## Testing Strategy

- **Unit tests:** All via sandbox adapter (no real LLM calls)
- **Structure validation:** Assert output shapes match expected schemas
- **Error paths:** Override sandbox to return errors, verify graceful handling
- **Integration with Ash:** Not in scope for this ticket (T-020-02 handles provisioning)
- **Live LLM tests:** Optional, gated behind env var like existing `baml_live` tag
