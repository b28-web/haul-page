# T-018-03 Design: Extraction Function

## Decision 1: BAML Prompt Design

**Chosen approach:** Single-shot extraction with explicit field instructions.

The prompt tells the LLM to extract all business info from a conversation transcript, infer ServiceCategory from descriptions, and return null for unknown fields. Key prompt elements:
- System context: "You are extracting business profile information from an operator onboarding conversation"
- Field-by-field guidance for ambiguous cases (category inference, area formatting)
- `{{ ctx.output_format }}` lets BAML handle JSON schema enforcement
- Input is the raw transcript string (not pre-structured)

**Rejected:** Multi-step extraction (extract fields separately then merge). Over-engineered for this use case — BAML's type system handles structured output in one pass.

## Decision 2: Extractor Module Architecture

**Chosen approach:** `Haul.AI.Extractor` as a thin orchestration layer.

```
extract_profile/1
  → Haul.AI.call_function("ExtractOperatorProfile", %{"transcript" => text})
  → OperatorProfile.from_baml(result)
  → return {:ok, profile} | {:error, reason}
```

The Extractor:
- Calls the AI adapter (Sandbox or Baml)
- Parses the raw map into an OperatorProfile struct
- Wraps errors into tagged tuples
- Retries once on transient errors

**Why not put this in `Haul.AI` directly?** The behaviour/adapter pattern is for raw LLM calls. Extraction is business logic (parse, validate, retry) that belongs in a separate module.

## Decision 3: Retry Strategy

**Chosen approach:** Single retry with error classification.

```elixir
defp transient?({:error, :timeout}), do: true
defp transient?({:error, :rate_limited}), do: true
defp transient?({:error, %{status: status}}) when status in [429, 500, 502, 503], do: true
defp transient?(_), do: false
```

On first failure:
- If transient → retry once immediately (no backoff — this is a user-facing conversation)
- If permanent → return error immediately
- If retry also fails → return the retry's error

**Rejected:** Exponential backoff, circuit breakers. This is a single user-facing call, not a high-throughput pipeline. One retry is sufficient.

## Decision 4: validate_completeness/1

**Chosen approach:** Delegate to `ProfileMapper.missing_fields/1` and add service_area.

The ticket says `validate_completeness/1` returns a list of missing required fields. `ProfileMapper.missing_fields/1` already does this for `[:business_name, :phone, :email]`. The Extractor version should include `service_area` (important for onboarding completeness) and also check for at least one service.

```elixir
def validate_completeness(%OperatorProfile{} = profile) do
  missing = ProfileMapper.missing_fields(profile)
  missing = if is_nil(profile.service_area), do: [:service_area | missing], else: missing
  missing = if profile.services == [], do: [:services | missing], else: missing
  missing
end
```

This drives the "we still need your..." UI feedback. Separate from ProfileMapper's check which is about Ash action requirements.

## Decision 5: Test Strategy

**Chosen approach:** Test at the Extractor level with controlled Sandbox responses.

For the 5+ fixture scenarios, we extend the Sandbox to pattern-match on the transcript content:
- Transcript containing specific marker phrases → returns specific fixture
- Default transcript → returns the existing full profile fixture

This keeps tests deterministic without live API calls. Each test fixture is a `{input_transcript, expected_output_map}` pair.

**Rejected:** Mocking with Mox. The adapter pattern already provides test isolation — the Sandbox IS the mock. Adding Mox would be redundant complexity.

**Rejected:** Storing fixtures in external files. The fixtures are small maps — inline in the Sandbox and test files is clearer.

## Decision 6: Sandbox Extension for Multiple Scenarios

**Chosen approach:** Add a process-based fixture override mechanism.

For tests that need non-default responses, use `Haul.AI.Sandbox.set_response/2` to override the fixture for the current test process:

```elixir
# In test setup
Sandbox.set_response("ExtractOperatorProfile", {:ok, partial_profile_map})
```

Uses the process dictionary or an Agent for test isolation. Falls back to the hardcoded fixture when no override is set. This avoids polluting the Sandbox with test-specific pattern matching.

**Implementation:** Process dictionary (`Process.get/put`) is simplest and already test-process-scoped. No cleanup needed since the process dies after the test.

## Summary of New/Modified Files

| File | Action | Purpose |
|------|--------|---------|
| `baml/main.baml` | Modify | Add ExtractOperatorProfile function + prompt |
| `lib/haul/ai/extractor.ex` | Create | extract_profile/1, validate_completeness/1 |
| `lib/haul/ai/sandbox.ex` | Modify | Add set_response/2 for test fixture overrides |
| `test/haul/ai/extractor_test.exs` | Create | 5+ conversation fixture tests |
