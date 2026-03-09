# T-018-03 Progress: Extraction Function

## Completed Steps

### Step 1: Extend Sandbox with fixture overrides ✓
- Added `set_response/2` using Process dictionary for per-test fixture control
- Refactored `call_function/2` to check overrides first, then fall back to `default_response/2`
- All 18 existing AI tests pass

### Step 2: Add BAML ExtractOperatorProfile function ✓
- Added function to `baml/main.baml` with detailed extraction prompt
- Prompt includes category inference guidance, null handling, multi-message support
- Uses existing OperatorProfile and ServiceCategory types

### Step 3: Create Extractor module ✓
- `lib/haul/ai/extractor.ex` created with `extract_profile/1` and `validate_completeness/1`
- Retry logic for transient errors (timeout, rate_limited, econnrefused, 429/500/502/503)
- `validate_completeness/1` extends ProfileMapper.missing_fields with service_area and services checks

### Step 4: Create Extractor tests ✓
- 13 tests covering all acceptance criteria scenarios
- 5 fixture conversations: complete, multi-message, ambiguous, partial, noisy
- Error handling tests for permanent and transient failures
- validate_completeness tests for all field combinations

### Step 5: Full test suite ✓
- 552 tests, 0 failures (up from 258 baseline — other tickets added tests too)
- No regressions

## Deviations from Plan
None.
