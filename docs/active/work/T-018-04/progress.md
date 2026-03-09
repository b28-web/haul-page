# T-018-04 Progress: Extraction Tests

## Completed

### Step 1: Added `valid_email?/1` to Extractor ✅
- Added `@email_pattern` regex and `valid_email?/1` function to `lib/haul/ai/extractor.ex`
- Returns false for nil, validates format for strings

### Step 2: Added `to_differentiators_content/1` to ProfileMapper ✅
- Added function to `lib/haul/ai/profile_mapper.ex`
- Converts differentiators list to markdown bullet-point string, nil for empty

### Step 3: Added missing extractor tests ✅
- Pure garbage input test (all-nil profile, no crash)
- Phone format preservation test (4 format variants)
- `valid_email?/1` tests: valid formats, invalid formats, nil

### Step 4: Added missing profile_mapper tests ✅
- `to_differentiators_content/1`: single item, multiple items, empty list

### Step 5: Created integration test file ✅
- `test/haul/ai/integration_test.exs` with `@moduletag :baml_live`
- Live extraction test with latency logging

### Step 6: Configured ExUnit exclusion ✅
- `test/test_helper.exs` updated to `exclude: [:baml_live]`

### Step 7: Full test suite ✅
- 575 tests, 0 failures, 1 excluded
- AI module: 56 tests, 0 failures, 1 excluded

## Test count change
- Before: 48 AI tests → After: 56 AI tests (+8 new)
- Before: 258 total (from OVERVIEW) → After: 575 total (includes work from other tickets)

## Deviations from plan
- None
