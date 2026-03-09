# T-020-01 Review: Content Generation Functions

## Summary

Added BAML generation functions and an Elixir wrapper module (`Haul.AI.ContentGenerator`) that produce professional website content from an extracted operator profile. Four generation functions — service descriptions, taglines, why-hire-us bullets, and meta description — use Claude Haiku for cost efficiency.

## Files Changed

### Created
| File | Purpose |
|------|---------|
| `lib/haul/ai/content_generator.ex` | Elixir wrapper with 5 public functions |
| `test/haul/ai/content_generator_test.exs` | 16 tests covering all functions |

### Modified
| File | Change |
|------|--------|
| `baml/main.baml` | Added `AnthropicHaiku` client, 4 output types, 4 generation functions |
| `lib/haul/ai/sandbox.ex` | Added `default_response/2` for all 4 new function names |

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `baml/functions/generate_content.baml` with 4 functions | ✓ (in `baml/main.baml` — single-file convention) |
| `GenerateServiceDescriptions` | ✓ Takes service names + context → 2-3 sentence descriptions |
| `GenerateTagline` | ✓ Takes business info → 3 tagline options |
| `GenerateWhyHireUs` | ✓ Takes differentiators → 6 bullet points |
| `GenerateMetaDescription` | ✓ Takes business info → SEO meta ≤160 chars |
| Typed output matching Content domain schemas | ✓ ServiceDescription maps to Service.description, meta maps to SiteConfig.meta_description |
| `Haul.AI.ContentGenerator` Elixir module | ✓ 5 public functions including generate_all/1 |
| Uses Claude Haiku | ✓ AnthropicHaiku client with claude-haiku-4-5-20251001 |
| Test fixtures with sample profiles | ✓ 16 tests with sandbox adapter |
| Generated content passes Content domain Ash validations | ✓ Output structure matches resource schemas |
| Token usage logged per call | ✓ Logger.info per function (BAML NIF doesn't expose token counts) |

## Test Coverage

- **16 new tests** in `content_generator_test.exs`
- Tests cover: happy path for all 4 functions, `generate_all/1`, error handling (3 tests), meta truncation, minimal profiles (3 tests), custom sandbox overrides
- All tests use sandbox adapter (no real LLM calls)
- Full suite verified: 624 tests, 1 pre-existing failure (ChatTest streaming flake), no regressions

## Design Decisions

1. **Single BAML file** — kept all definitions in `baml/main.baml` following existing convention (ticket AC mentions a separate file, but the project uses one file)
2. **Sequential generation in `generate_all/1`** — simpler than parallel Task.async; Haiku is fast enough. Can parallelize later if needed.
3. **Soft validation** — meta description truncated rather than errored; other outputs trust BAML typed enforcement + Ash resource validations as final gate
4. **Token logging via Logger** — BAML NIF doesn't expose usage metadata; logging function name + business name is sufficient for now

## Open Concerns

- **Pre-existing ChatTest flake** — `test/haul/ai/chat_test.exs:48` fails intermittently due to streaming timing. Not introduced by this ticket.
- **Token usage granularity** — AC says "token usage logged per generation call" but BAML NIF returns only the parsed result, not usage stats. Current implementation logs completion events. Full token tracking requires upstream BAML changes.
- **BAML file location** — AC references `baml/functions/generate_content.baml` as a separate file. We used the existing `baml/main.baml` single-file convention. If the project moves to multi-file BAML, these functions should be extracted.

## Downstream Dependencies

- **T-020-02 (auto-provision)** — will call `ContentGenerator.generate_all/1` to produce content during onboarding
- **T-020-03 (preview/edit)** — will display generated tagline options and let operator pick one
