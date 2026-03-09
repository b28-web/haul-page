# T-020-01 Progress: Content Generation Functions

## Step 1: Add BAML types and functions — DONE
- Added `AnthropicHaiku` client (claude-haiku-4-5-20251001) to `baml/main.baml`
- Added 4 output types: `ServiceDescription`, `TaglineOptions`, `WhyHireUsBullets`, `MetaDescriptionResult`
- Added 4 generation functions: `GenerateServiceDescriptions`, `GenerateTagline`, `GenerateWhyHireUs`, `GenerateMetaDescription`
- Each function uses `AnthropicHaiku` client for cost efficiency

## Step 2: Add sandbox responses — DONE
- Added `default_response/2` clauses for all 4 generation functions in `Haul.AI.Sandbox`
- `GenerateServiceDescriptions` generates dynamic responses based on input service_names
- `GenerateTagline` returns 3 sample taglines
- `GenerateWhyHireUs` returns 6 bullet points
- `GenerateMetaDescription` returns description using input business_name and service_area

## Step 3: Create ContentGenerator module — DONE
- Created `lib/haul/ai/content_generator.ex` with 5 public functions
- `generate_service_descriptions/1`, `generate_taglines/1`, `generate_why_hire_us/1`, `generate_meta_description/1`, `generate_all/1`
- Retry logic for transient errors (timeout, rate_limited, 429/500/502/503)
- Meta description truncation to 160 chars
- Logger.info for completion tracking per function

## Step 4: Create ContentGenerator tests — DONE
- Created `test/haul/ai/content_generator_test.exs` with 16 tests
- Tests cover: output structure, service name matching, exact counts, error handling, truncation, minimal profiles, custom sandbox overrides, generate_all consolidation

## Step 5: Run full test suite — DONE
- ContentGenerator tests: 16/16 passing
- AI test suite: 92/93 passing (1 pre-existing flaky chat streaming test)
- No regressions introduced

## Deviations from Plan
None. Implementation followed the plan exactly.
