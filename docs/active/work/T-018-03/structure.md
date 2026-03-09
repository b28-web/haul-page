# T-018-03 Structure: Extraction Function

## File Changes

### 1. `baml/main.baml` — MODIFY

Add `ExtractOperatorProfile` function after the existing `ExtractName` function:
- Input: `transcript: string`
- Output: `OperatorProfile`
- Client: `Anthropic`
- Prompt: multi-line template with extraction instructions, category inference guidance, `{{ ctx.output_format }}`

### 2. `lib/haul/ai/extractor.ex` — CREATE

Module: `Haul.AI.Extractor`

Public interface:
```
extract_profile(transcript :: String.t()) :: {:ok, OperatorProfile.t()} | {:error, term()}
validate_completeness(profile :: OperatorProfile.t()) :: [atom()]
```

Internal functions:
```
do_extract(transcript) — single attempt: call_function + from_baml
transient?(result) — classify errors for retry
```

Dependencies:
- `Haul.AI` (call_function)
- `Haul.AI.OperatorProfile` (from_baml)
- `Haul.AI.ProfileMapper` (missing_fields)

### 3. `lib/haul/ai/sandbox.ex` — MODIFY

Add process dictionary-based fixture override:
```
set_response(function_name, response) — stores in Process dictionary
get_response(function_name) — checks Process dictionary, falls back to hardcoded
```

Modify `call_function/2` clauses to check for override first via a shared entry point.

### 4. `test/haul/ai/extractor_test.exs` — CREATE

Test module: `Haul.AI.ExtractorTest`

Describe blocks:
- `extract_profile/1`
  - complete conversation → full OperatorProfile
  - multi-message conversation → profile assembled from scattered info
  - ambiguous services → categories inferred
  - partial info → profile with nils, returns {:ok, profile} (not error)
  - irrelevant content mixed in → extracts business info only
  - API error → returns {:error, reason}
  - transient error with retry → retries and returns result
- `validate_completeness/1`
  - complete profile → empty list
  - missing required fields → lists them
  - no services → includes :services
  - missing service_area → includes :service_area

Each test sets up its fixture via `Sandbox.set_response/2`.

## Module Boundaries

```
Haul.AI.Extractor (new)
  ├── uses Haul.AI.call_function/2 (adapter delegation)
  ├── uses Haul.AI.OperatorProfile.from_baml/1 (parsing)
  └── uses Haul.AI.ProfileMapper.missing_fields/1 (validation)

Haul.AI.Sandbox (modified)
  └── adds set_response/2 override mechanism
```

## Ordering

1. Modify `sandbox.ex` (test infrastructure first)
2. Add BAML function to `main.baml`
3. Create `extractor.ex`
4. Create `extractor_test.exs`
