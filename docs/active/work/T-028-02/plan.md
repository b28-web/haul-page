# T-028-02 Plan: Implementation Steps

## Step 1: Create `Haul.Billing.PlanLogic` + tests

1. Create `lib/haul/billing/plan_logic.ex` with `plans/0`, `plan_features/1`, `can?/2`, `feature_label/1`
2. Move `@feature_matrix` and `@feature_labels` module attributes
3. Create `test/haul/billing/plan_logic_test.exs` (async: true)
4. Tests: all plans returned, feature lists correct, can? true/false, unknown plan, feature_label for known/unknown
5. Modify `lib/haul/billing.ex` to delegate these 4 functions to PlanLogic
6. Run: `mix test test/haul/billing/`
7. **Target: 10 tests**

## Step 2: Create `Haul.AI.ErrorClassifier` + tests

1. Create `lib/haul/ai/error_classifier.ex` with `transient?/1`
2. Create `test/haul/ai/error_classifier_test.exs` (async: true)
3. Tests: timeout, rate_limited, econnrefused, 429, 500, 502, 503, non-transient errors, unknown tuples
4. Modify `lib/haul/ai/content_generator.ex` — remove `transient?/1`, alias and call ErrorClassifier
5. Modify `lib/haul/ai/extractor.ex` — same change
6. Run: `mix test test/haul/ai/`
7. **Target: 6 tests**

## Step 3: Create `Haul.Content.Markdown` + tests

1. Create `lib/haul/content/markdown.ex` with `render_html/1`, `parse_frontmatter!/1`, `strip_frontmatter/1`, `parse_version/1`
2. Create `test/haul/content/markdown_test.exs` (async: true)
3. Tests: render basic markdown, render with extensions (tables, footnotes), parse valid frontmatter, parse invalid (raises), strip with/without frontmatter, parse_version present/missing/no frontmatter
4. Modify `lib/haul/content/page.ex` — replace inline MDEx calls with `Markdown.render_html/1`
5. Modify `lib/haul/content/seeder.ex` — delegate `parse_frontmatter!/1` to Markdown
6. Modify `lib/haul/ai/prompt.ex` — delegate `strip_frontmatter/1` and `parse_version/1` to Markdown
7. Run: `mix test test/haul/content/`
8. **Target: 8 tests**

## Step 4: Create `Haul.Workers.ProfileSerializer` + tests

1. Create `lib/haul/workers/profile_serializer.ex` with `serialize/1`, `deserialize/1`, `safe_atom/1`
2. Create `test/haul/workers/profile_serializer_test.exs` (async: true)
3. Tests: serialize round-trip, deserialize with services, safe_atom known/unknown/nil/atom, empty services list
4. Modify `lib/haul/workers/provision_site.ex` — delegate to ProfileSerializer
5. Run: `mix test test/haul/workers/`
6. **Target: 6 tests**

## Step 5: Unit tests for in-place functions

1. Create `test/haul/domains_test.exs` — normalize_domain (protocol stripping, path removal, downcasing, edge cases), valid_domain? (valid/invalid formats)
2. Create `test/haul/onboarding_unit_test.exs` — derive_slug (spaces, special chars, leading/trailing hyphens, empty)
3. Create `test/haul/ai/cost_tracker_unit_test.exs` — estimate_tokens (short/long text, empty), estimate_cost (known models, default), model_for_function (known/unknown)
4. Create `test/haul/ai/extractor_unit_test.exs` — valid_email? (valid/invalid/nil)
5. Run: `mix test test/haul/domains_test.exs test/haul/onboarding_unit_test.exs test/haul/ai/cost_tracker_unit_test.exs test/haul/ai/extractor_unit_test.exs`
6. **Target: 14 tests**

## Step 6: Full suite verification

1. Run `mix test` — all 845+ existing tests must pass
2. Verify new test count ≥ 30
3. Document results

## Test Total: ~44 new unit tests (exceeds 30+ target)
