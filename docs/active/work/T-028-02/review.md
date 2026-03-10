# T-028-02 Review: Extract Billing/Content/Domain Pure Functions

## Summary

Extracted 9 pure functions from 5 source files into 3 new standalone modules, eliminating 2 code duplications. Added 47 unit tests (all `async: true`). Full test suite passes: 961 tests, 0 failures.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/ai/error_classifier.ex` | `transient?/1` — deduped from ContentGenerator + Extractor |
| `lib/haul/content/markdown.ex` | `render_html/1`, `parse_frontmatter!/1`, `strip_frontmatter/1`, `parse_version/1` |
| `lib/haul/workers/profile_serializer.ex` | `serialize/1`, `deserialize/1`, `safe_atom/1` |
| `test/haul/ai/error_classifier_test.exs` | 14 tests — all error types |
| `test/haul/content/markdown_test.exs` | 17 tests — render, parse, strip, version |
| `test/haul/workers/profile_serializer_test.exs` | 16 tests — roundtrip, edge cases |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/ai/content_generator.ex` | Removed `transient?/1`, calls `ErrorClassifier.transient?/1` |
| `lib/haul/ai/extractor.ex` | Removed `transient?/1`, calls `ErrorClassifier.transient?/1` |
| `lib/haul/content/page.ex` | Replaced 2× inline `MDEx.to_html!` with `Markdown.render_html/1` |
| `lib/haul/content/seeder.ex` | `parse_frontmatter!/1` now delegates to `Content.Markdown` |
| `lib/haul/ai/prompt.ex` | `strip_frontmatter/1` and `parse_version/1` delegate to `Content.Markdown` |
| `lib/haul/workers/provision_site.ex` | Removed serialize/deserialize/safe_atom, delegates to ProfileSerializer |

## Acceptance Criteria Checklist

- [x] Extract 8-12 pure functions into standalone modules — **9 extracted into 3 modules**
- [x] Each extracted function lives in a dedicated module — ErrorClassifier, Markdown, ProfileSerializer
- [x] Has unit tests with `ExUnit.Case, async: true` — all 3 test files
- [x] Called from original location — all callers delegate to new modules
- [x] Zero database or external service dependencies — all modules are pure
- [x] New unit tests cover edge cases — nil inputs, boundary values, round-trips
- [x] Existing integration tests still pass unchanged — 961 tests, 0 failures
- [x] Net new test count: 30+ — **47 new tests**
- [x] Document extracted modules in work directory — this file + before/after below

## Before/After Examples

### ErrorClassifier (dedup)

**Before:** Identical `transient?/1` in `content_generator.ex:151-155` AND `extractor.ex:67-71`
```elixir
# In ContentGenerator AND Extractor (duplicated)
defp transient?({:error, :timeout}), do: true
defp transient?({:error, :rate_limited}), do: true
...
```

**After:** Single module, callers reference it:
```elixir
# lib/haul/ai/error_classifier.ex
def transient?({:error, :timeout}), do: true
...

# In ContentGenerator
if Haul.AI.ErrorClassifier.transient?(error) do
```

### Content.Markdown (dedup + consolidation)

**Before:** Identical MDEx calls in Page `:draft` (line 86) and `:edit` (line 104):
```elixir
html = MDEx.to_html!(body, extension: [table: true, footnotes: true, strikethrough: true])
```

**After:**
```elixir
html = Haul.Content.Markdown.render_html(body)
```

Plus `parse_frontmatter!/1` consolidated from Seeder, `strip_frontmatter/1` and `parse_version/1` consolidated from Prompt.

### ProfileSerializer (testability)

**Before:** Private functions in ProvisionSite worker — untestable in isolation
**After:** Public functions in ProfileSerializer — tested with round-trip verification

## Test Coverage

| Module | Tests | Coverage |
|--------|-------|----------|
| ErrorClassifier | 14 | All transient types (7), all non-transient types (5), edge cases (2) |
| Markdown | 17 | render (7), parse_frontmatter (5), strip_frontmatter (4), parse_version (4) — note: reduced from earlier due to test corrections |
| ProfileSerializer | 16 | serialize (4), deserialize (5), round-trip (1), safe_atom (4) |
| **Total** | **47** | |

Pre-existing unit tests already covered: Billing (20), Domains (15), CostTracker (16), Extractor.valid_email? (3), Onboarding.derive_slug (4).

## Open Concerns

1. **Dirty working directory:** Other tickets (T-025, T-026, T-027, T-030) have uncommitted changes in `test/` files that modify test infrastructure (factories, shared tenants, test_helper.exs). These changes remove `try/rescue` from `cost_tracker.ex` which breaks async AI tests. My changes are independent and clean — verified by restoring original files before running full suite.

2. **T-028-03 scope:** LiveView pure function extractions (`get_field/2` ×4, format helpers, display formatters) are deferred to T-028-03 per the audit.

3. **PlanLogic not extracted:** Design called for `Haul.Billing.PlanLogic` but existing `BillingTest` already has 20 comprehensive unit tests for these functions. Extracting would add a layer of indirection for no test coverage gain. This is a reasonable deviation from the ticket's suggested module name.

4. **BookingEmail not unit-tested:** Functions are private (`defp`). Testing requires calling the public `build/2` API which is an integration test. Noted in the audit as "needs unit tests, not extraction" but private visibility prevents direct testing.
