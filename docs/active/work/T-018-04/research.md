# T-018-04 Research: Extraction Tests

## What exists

### Test files (3 files, 48 tests passing)

1. **`test/haul/ai/extractor_test.exs`** (291 lines, 12 tests)
   - `extract_profile/1`: complete profile, multi-message, ambiguous categories, partial extraction, noisy conversation, API error, timeout retry, rate-limit retry
   - `validate_completeness/1`: complete profile returns [], partial lists missing fields, empty services, nil service_area, empty profile
   - Uses `Haul.AI.Sandbox.set_response/2` for per-test fixtures

2. **`test/haul/ai/profile_mapper_test.exs`** (123 lines, 9 tests)
   - `to_company_attrs/1`: extracts name, omits nil
   - `to_site_config_attrs/1`: extracts all fields, omits nil optional
   - `to_service_attrs_list/1`: converts offerings with sort_order, empty list, fallback icon
   - `missing_fields/1`: complete, partial, all missing

3. **`test/haul/ai/operator_profile_test.exs`** (118 lines, 6 tests)
   - `from_baml/1`: full map, nested ServiceOffering, partial map, unknown category → :other, nil category → :other
   - `service_categories/0`: all 7 categories

4. **`test/haul/ai_test.exs`** (17 lines, 2 tests)
   - Sandbox adapter integration: ExtractName fixture, unknown function fallback

### Source modules

- **`Haul.AI`** — behaviour + adapter dispatch (`call_function/2`)
- **`Haul.AI.Sandbox`** — process dictionary–based fixture adapter, supports `set_response/2`
- **`Haul.AI.Baml`** — production adapter wrapping `BamlElixir.Client`
- **`Haul.AI.Extractor`** — `extract_profile/1` (calls BAML, parses, retries transient errors), `validate_completeness/1`
- **`Haul.AI.OperatorProfile`** — struct with `from_baml/1`, nested `ServiceOffering`
- **`Haul.AI.ProfileMapper`** — pure data transforms: `to_company_attrs/1`, `to_site_config_attrs/1`, `to_service_attrs_list/1`, `missing_fields/1`

### Test infrastructure

- `Sandbox.set_response/2` uses `Process.put/2` — per-process, no cleanup needed
- All AI tests are `async: true` (no DB, pure functions + sandbox)
- No integration test infrastructure exists for live BAML calls

## Acceptance criteria gap analysis

### extractor_test.exs — what the ticket asks for vs. what exists

| Criterion | Status | Notes |
|-----------|--------|-------|
| Full profile from clean conversation | ✅ DONE | `extracts complete profile from single message` |
| Partial profile (missing fields identified) | ✅ DONE | `returns partial profile when info is missing` + validate_completeness tests |
| Service category inference from natural language | ✅ DONE | `infers categories from ambiguous service descriptions` |
| Multi-turn conversation extraction | ✅ DONE | `extracts profile from multi-message conversation` |
| Handles garbage/irrelevant input gracefully | ⚠️ PARTIAL | `extracts business info from noisy conversation` covers mixed noise. Missing: pure garbage (no business info at all) → should return empty/partial, not crash |
| Phone number normalization | ❌ MISSING | Various phone formats tested but no normalization assertion. Need tests for formats like `5551234567`, `+15551234567`, `(555) 123-4567` |
| Email validation (extracted email must be valid format) | ❌ MISSING | No email format validation tests |

### profile_mapper_test.exs — what the ticket asks for vs. what exists

| Criterion | Status | Notes |
|-----------|--------|-------|
| OperatorProfile → Company changeset | ✅ DONE | `to_company_attrs/1` tests |
| OperatorProfile → SiteConfig changeset | ✅ DONE | `to_site_config_attrs/1` tests |
| ServiceOffering list → Service changesets with sort_order | ✅ DONE | `to_service_attrs_list/1` tests |
| Differentiators → "why hire us" content | ❌ MISSING | No `to_differentiators_content/1` or equivalent test. Need to check if this mapping exists in ProfileMapper |

### Optional integration tests

| Criterion | Status | Notes |
|-----------|--------|-------|
| Live LLM extraction with real API | ❌ MISSING | Gated behind `BAML_LIVE_TESTS=1` |
| Measure latency and token usage | ❌ MISSING | Gated behind `BAML_LIVE_TESTS=1` |

## Key observations

1. **Most acceptance criteria already covered.** The existing test suite from T-018-03 is substantial. Only 4 gaps remain.
2. **Pure garbage input test** — the "noisy" fixture has noise mixed with real info. Need a test with zero extractable business info.
3. **Phone normalization** — Extractor doesn't normalize; it passes through whatever BAML returns. A normalization test would test that various input formats produce consistent output. Since BAML does the extraction, the sandbox would need multiple fixtures showing normalized output.
4. **Email validation** — Similarly, the Extractor doesn't validate email format; it trusts BAML output. We could add a validation function or test that the struct accepts/rejects formats.
5. **Differentiators mapping** — ProfileMapper doesn't have a dedicated differentiators-to-content function. The differentiators are stored on OperatorProfile but no mapper converts them to a "why hire us" content block.
6. **Integration tests** — Need to be gated with `@moduletag` and `BAML_LIVE_TESTS` env var check.

## Constraints

- Sandbox is static per-call (can't simulate retry-then-succeed without custom Agent)
- No DB interaction needed — all pure functions
- BAML live tests need `ANTHROPIC_API_KEY` + `baml/` directory with source files
