# T-020-01 Structure: Content Generation Functions

## Files Modified

### `baml/main.baml`
Add after existing function definitions:
- `AnthropicHaiku` client definition (claude-haiku-4-5-20251001)
- `ServiceDescription` class (service_name, description)
- `TaglineOptions` class (options: string[])
- `WhyHireUsBullets` class (bullets: string[])
- `MetaDescriptionResult` class (description: string)
- `GenerateServiceDescriptions` function (client: AnthropicHaiku)
- `GenerateTagline` function (client: AnthropicHaiku)
- `GenerateWhyHireUs` function (client: AnthropicHaiku)
- `GenerateMetaDescription` function (client: AnthropicHaiku)

### `lib/haul/ai/sandbox.ex`
Add `default_response/2` clauses for:
- `"GenerateServiceDescriptions"` — returns 3 service descriptions
- `"GenerateTagline"` — returns 3 tagline options
- `"GenerateWhyHireUs"` — returns 6 bullet points
- `"GenerateMetaDescription"` — returns sample meta description

## Files Created

### `lib/haul/ai/content_generator.ex`
Module: `Haul.AI.ContentGenerator`

Public functions:
- `generate_service_descriptions(profile)` — calls GenerateServiceDescriptions BAML function, parses result
- `generate_taglines(profile)` — calls GenerateTagline, returns list of 3 strings
- `generate_why_hire_us(profile)` — calls GenerateWhyHireUs, returns list of 6 strings
- `generate_meta_description(profile)` — calls GenerateMetaDescription, returns single string
- `generate_all(profile)` — calls all four, returns consolidated map

Private helpers:
- `build_service_context(profile)` — builds args map for service description generation
- `build_business_context(profile)` — builds args map for tagline/meta generation
- `with_retry(fun)` — retry wrapper for transient errors (same pattern as Extractor)
- `log_completion(function_name, profile)` — Logger.info with function name

### `test/haul/ai/content_generator_test.exs`
Module: `Haul.AI.ContentGeneratorTest`

Test cases:
- `generate_service_descriptions/1` returns descriptions matching service count
- `generate_taglines/1` returns exactly 3 options
- `generate_why_hire_us/1` returns exactly 6 bullets
- `generate_meta_description/1` returns string ≤160 chars
- `generate_all/1` returns map with all four keys
- Each function handles error responses gracefully
- Custom sandbox overrides work per-process
- Generated service descriptions match input service names
- Meta description is non-empty
- All outputs are non-nil strings

## Module Boundaries

```
Haul.AI.ContentGenerator
  ├── calls → Haul.AI.call_function/2 (adapter dispatch)
  ├── input → Haul.AI.OperatorProfile (typed struct)
  ├── output → plain maps/lists (not Ash resources)
  └── consumed by → T-020-02 auto-provision pipeline (future)

Haul.AI.Sandbox
  └── extended with → 4 new default_response clauses
```

## Ordering

1. BAML types and functions (baml/main.baml) — foundation
2. Sandbox responses (sandbox.ex) — enables testing
3. ContentGenerator module (content_generator.ex) — core logic
4. Tests (content_generator_test.exs) — verification
