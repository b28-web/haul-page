# T-018-03 Review: Extraction Function

## Summary

Built the BAML extraction function and Elixir wrapper that turns a conversation transcript into a typed OperatorProfile. This is the core AI capability for the onboarding pipeline.

## Files Changed

| File | Action | Lines | Purpose |
|------|--------|-------|---------|
| `baml/main.baml` | Modified | +33 | Added `ExtractOperatorProfile` function with extraction prompt |
| `lib/haul/ai/extractor.ex` | Created | 62 | `extract_profile/1` + `validate_completeness/1` with retry logic |
| `lib/haul/ai/sandbox.ex` | Modified | +17 | Added `set_response/2` for per-test fixture overrides |
| `test/haul/ai/extractor_test.exs` | Created | 218 | 13 tests with 5 conversation fixtures |

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| `baml/functions/extract_profile.baml` | ✓ | Function in `main.baml` (single BAML source file pattern) |
| Input: conversation transcript (string) | ✓ | `transcript: string` parameter |
| Output: OperatorProfile (typed) | ✓ | Returns typed BAML OperatorProfile |
| Prompt: extract, infer category, null unknowns | ✓ | Detailed prompt with category guidance |
| `Haul.AI.Extractor.extract_profile/1` | ✓ | Returns `{:ok, %OperatorProfile{}}` or `{:error, reason}` |
| Handles API errors, timeouts, rate limits | ✓ | Error classification with `transient?/1` |
| Retries once on transient failure | ✓ | Single retry, no backoff |
| `Haul.AI.Extractor.validate_completeness/1` | ✓ | Returns missing: business_name, phone, email, service_area, services |
| 5+ sample conversations | ✓ | 5 fixtures: complete, multi-message, ambiguous, partial, noisy |
| Tests use recorded responses | ✓ | Sandbox adapter with `set_response/2` overrides |

## Test Coverage

- **13 new tests** in `test/haul/ai/extractor_test.exs`
  - 8 tests for `extract_profile/1` (5 fixture scenarios + 2 error + 1 retry)
  - 5 tests for `validate_completeness/1` (complete, missing fields, no services, no area, empty)
- **552 total tests**, 0 failures (no regressions)
- All tests async-safe (Process dictionary scoping)

## Design Decisions

1. **Sandbox `set_response/2` uses Process dictionary** — simplest approach for test-scoped overrides, no cleanup needed.
2. **`validate_completeness/1` extends `ProfileMapper.missing_fields/1`** — adds `service_area` and `services` checks relevant to onboarding completeness (vs. ProfileMapper which checks Ash action requirements only).
3. **Single retry, no backoff** — user-facing conversation context; exponential backoff would degrade UX.
4. **BAML function in `main.baml`** — follows existing pattern (single BAML source file), not a separate file as the ticket suggested.

## Open Concerns

1. **Retry test limitation** — `set_response/2` returns the same response for every call, so we can't test "fail then succeed" in a single test. The retry code path is exercised (transient error → retry → same error), but the "retry succeeds" scenario isn't directly tested. Could add a call-counting mechanism to Sandbox if needed.
2. **BAML prompt not validated against live LLM** — the prompt is written but untested against a real Anthropic API call. Should be validated manually before production use.
3. **No input validation** — `extract_profile/1` accepts any string, including empty. The BAML function will handle this gracefully (returning nulls), but an explicit check could improve error messages.

## Downstream Impact

- **T-019-02 (live extraction)** can now call `Extractor.extract_profile/1` from the chat LiveView
- **T-019-05 (fallback form)** can use `validate_completeness/1` to show missing fields
- **T-020-01 (content generation)** consumes the OperatorProfile struct
