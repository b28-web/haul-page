# T-018-04 Design: Extraction Tests

## Approach

Most acceptance criteria are already met by the existing test suite from T-018-03. This ticket fills 4 gaps and adds optional live integration tests.

## Gap 1: Pure garbage input test

**Decision:** Add a test where transcript is pure nonsense — no business name, no phone, no services. Set sandbox response to return an empty/all-nil profile map. Assert `extract_profile/1` returns `{:ok, %OperatorProfile{}}` with all nil fields and empty lists (not a crash or error).

**Rationale:** The "noisy" test has extractable info mixed with noise. We need to verify the pipeline handles zero-signal input gracefully.

## Gap 2: Phone number normalization

**Decision:** Add tests showing the Extractor passes through BAML's normalized output. The BAML function is responsible for normalization; the Elixir side preserves it. Test with fixtures showing various input formats producing consistent format in the result.

**Alternative considered:** Adding an Elixir-side normalization function. Rejected — the BAML extraction function already handles this, and adding redundant normalization adds complexity with no benefit.

**Implementation:** Add 2-3 fixture variants with different phone formats in the sandbox response, verify the struct stores them correctly.

## Gap 3: Email validation

**Decision:** Add a validation function `Extractor.valid_email?/1` (simple regex check) and test it, rather than modifying `extract_profile/1`. The Extractor should not reject profiles with bad emails — that's a completeness check. But we should be able to flag invalid emails.

**Alternative considered:** Rejecting profiles with invalid emails. Rejected — partial profiles are explicitly supported, and a bad email is better caught downstream (in the onboarding UI) than discarded.

**Implementation:** Add `valid_email?/1` to Extractor. Test with valid formats, invalid formats, and nil.

## Gap 4: Differentiators → "why hire us" content

**Decision:** Add `ProfileMapper.to_differentiators_content/1` that converts the differentiators list into a markdown string suitable for the "why hire us" section. Test the mapping.

**Alternative considered:** Storing differentiators as a list in SiteConfig. Rejected — SiteConfig doesn't have a differentiators field; they need to be converted to content for the "why us" page section.

**Implementation:** Simple join of differentiators into bullet-point markdown. Return nil if empty list.

## Gap 5: Integration tests (optional)

**Decision:** Create `test/haul/ai/integration_test.exs` gated with `@moduletag :baml_live`. Configure ExUnit to exclude `:baml_live` by default. Tests only run with `BAML_LIVE_TESTS=1 mix test --include baml_live`.

**Tests:**
1. Send a complete conversation transcript to real BAML → verify result is `{:ok, %OperatorProfile{}}` with non-nil business_name
2. Measure extraction time (log, don't assert — LLM latency varies)

## Test organization

All new fixture-based tests go in existing test files. Integration tests get their own file. No structural changes to existing test infrastructure.
