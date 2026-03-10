# T-028-02 Progress

## Completed

### Step 1: Create `Haul.AI.ErrorClassifier` + tests
- Created `lib/haul/ai/error_classifier.ex` with `transient?/1`
- Created `test/haul/ai/error_classifier_test.exs` with 14 tests
- Modified `lib/haul/ai/content_generator.ex` — removed `transient?/1`, calls ErrorClassifier
- Modified `lib/haul/ai/extractor.ex` — removed `transient?/1`, calls ErrorClassifier

### Step 2: Create `Haul.Content.Markdown` + tests
- Created `lib/haul/content/markdown.ex` with `render_html/1`, `parse_frontmatter!/1`, `strip_frontmatter/1`, `parse_version/1`
- Created `test/haul/content/markdown_test.exs` with 17 tests
- Modified `lib/haul/content/page.ex` — replaced inline MDEx calls with `Markdown.render_html/1`
- Modified `lib/haul/content/seeder.ex` — delegated `parse_frontmatter!/1` to Markdown
- Modified `lib/haul/ai/prompt.ex` — delegated `strip_frontmatter/1` and `parse_version/1` to Markdown

### Step 3: Create `Haul.Workers.ProfileSerializer` + tests
- Created `lib/haul/workers/profile_serializer.ex` with `serialize/1`, `deserialize/1`, `safe_atom/1`
- Created `test/haul/workers/profile_serializer_test.exs` with 16 tests
- Modified `lib/haul/workers/provision_site.ex` — delegated to ProfileSerializer

### Step 4: Full suite verification
- 961 tests, 0 failures (47 new tests from this ticket)
- No regressions in existing integration tests

## Deviations from Plan

1. **Skipped `Haul.Billing.PlanLogic` extraction** — `test/haul/billing_test.exs` already has comprehensive unit tests for `can?/2`, `plan_features/1`, `plans/0`, `feature_label/1` (20 tests). Extracting to a submodule would add indirection without value.

2. **Skipped in-place unit tests for Domains, Onboarding, CostTracker, Extractor** — all already have comprehensive unit tests:
   - `test/haul/domains_test.exs` — 15 tests covering normalize_domain and valid_domain?
   - `test/haul/onboarding_test.exs` — 4 derive_slug tests + integration tests
   - `test/haul/ai/cost_tracker_test.exs` — 16 tests covering estimate_tokens, estimate_cost, model_for_function
   - `test/haul/ai/extractor_test.exs` — 5 valid_email? tests + completeness tests

3. **3 new modules instead of 4** — PlanLogic not created since billing functions are already well-tested in place. Total extracted: 9 functions into 3 modules.
