# T-018-04 Structure: Extraction Tests

## Files modified

### `test/haul/ai/extractor_test.exs`
- Add `@garbage_transcript` and `@garbage_response` fixtures (empty/nil profile)
- Add test: "handles pure garbage input gracefully"
- Add `@phone_formats_response` fixture with normalized phone
- Add test: "preserves phone format from extraction"
- Add tests for `valid_email?/1`: valid, invalid, nil

### `lib/haul/ai/extractor.ex`
- Add `valid_email?/1` public function — simple regex-based email format check
- Spec: `@spec valid_email?(String.t() | nil) :: boolean()`

### `test/haul/ai/profile_mapper_test.exs`
- Add tests for `to_differentiators_content/1`: with items, empty list, nil handling

### `lib/haul/ai/profile_mapper.ex`
- Add `to_differentiators_content/1` — converts differentiators list to markdown bullet string
- Spec: `@spec to_differentiators_content(OperatorProfile.t()) :: String.t() | nil`

### `test/haul/ai/integration_test.exs` (NEW)
- Module: `Haul.AI.IntegrationTest`
- `@moduletag :baml_live`
- Test: "extracts profile from real LLM call"
- Test: "measures extraction latency"

### `test/test_helper.exs`
- Add `ExUnit.configure(exclude: [:baml_live])` to exclude live tests by default

## Files NOT modified

- `Haul.AI.Sandbox` — no changes needed, `set_response/2` handles all fixtures
- `Haul.AI.OperatorProfile` — struct is fine as-is
- `Haul.AI.Baml` — production adapter unchanged

## Module boundaries

- `Extractor.valid_email?/1` is a pure utility — no side effects
- `ProfileMapper.to_differentiators_content/1` follows existing pattern of pure data transforms
- Integration tests bypass sandbox, use `Haul.AI.Baml` directly

## Ordering

1. Add `valid_email?/1` to Extractor
2. Add `to_differentiators_content/1` to ProfileMapper
3. Add new tests to extractor_test.exs
4. Add new tests to profile_mapper_test.exs
5. Create integration_test.exs
6. Update test_helper.exs
