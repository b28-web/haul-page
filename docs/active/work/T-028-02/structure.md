# T-028-02 Structure: File-Level Changes

## New Files

### Source Modules

| File | Purpose |
|------|---------|
| `lib/haul/billing/plan_logic.ex` | Pure plan definitions, feature matrix, feature labels |
| `lib/haul/ai/error_classifier.ex` | `transient?/1` — single source of error classification |
| `lib/haul/content/markdown.ex` | `render_html/1`, `parse_frontmatter!/1`, `strip_frontmatter/1`, `parse_version/1` |
| `lib/haul/workers/profile_serializer.ex` | `serialize/1`, `deserialize/1`, `safe_atom/1` |

### Test Files

| File | Tests For |
|------|-----------|
| `test/haul/billing/plan_logic_test.exs` | PlanLogic — plans, features, can?, labels |
| `test/haul/ai/error_classifier_test.exs` | ErrorClassifier — transient? for all error types |
| `test/haul/content/markdown_test.exs` | Markdown — render, parse, strip, version |
| `test/haul/workers/profile_serializer_test.exs` | ProfileSerializer — round-trip serialization |
| `test/haul/domains_test.exs` | Domains — normalize_domain, valid_domain? |
| `test/haul/onboarding_unit_test.exs` | Onboarding — derive_slug edge cases |
| `test/haul/ai/cost_tracker_unit_test.exs` | CostTracker — estimate_tokens, estimate_cost, model_for_function |
| `test/haul/ai/extractor_unit_test.exs` | Extractor — valid_email? edge cases |

## Modified Files

### Source Modules (delegate to extracted modules)

| File | Change |
|------|--------|
| `lib/haul/billing.ex` | Move `@feature_matrix`, `@feature_labels`, `plans/0`, `plan_features/1`, `can?/2`, `feature_label/1` to PlanLogic. Add delegating wrappers. |
| `lib/haul/ai/content_generator.ex` | Remove `transient?/1`, call `ErrorClassifier.transient?/1` |
| `lib/haul/ai/extractor.ex` | Remove `transient?/1`, call `ErrorClassifier.transient?/1` |
| `lib/haul/ai/prompt.ex` | Remove `strip_frontmatter/1`, `parse_version/1`, delegate to `Content.Markdown` |
| `lib/haul/content/seeder.ex` | Remove `parse_frontmatter!/1`, delegate to `Content.Markdown` |
| `lib/haul/content/page.ex` | Replace inline MDEx calls with `Content.Markdown.render_html/1` |
| `lib/haul/workers/provision_site.ex` | Remove `serialize_profile/1`, `deserialize_profile/1`, `safe_atom/1`, delegate to ProfileSerializer |

## Module Interfaces

### `Haul.Billing.PlanLogic`
```elixir
@spec plans() :: [map()]
@spec plan_features(atom()) :: [atom()]
@spec can?(map(), atom()) :: boolean()
@spec feature_label(atom()) :: String.t()
```

### `Haul.AI.ErrorClassifier`
```elixir
@spec transient?({:error, term()}) :: boolean()
```

### `Haul.Content.Markdown`
```elixir
@spec render_html(String.t()) :: String.t()
@spec parse_frontmatter!(String.t()) :: {map(), String.t()}
@spec strip_frontmatter(String.t()) :: String.t()
@spec parse_version(String.t()) :: {:ok, String.t()} | {:error, atom()}
```

### `Haul.Workers.ProfileSerializer`
```elixir
@spec serialize(OperatorProfile.t()) :: map()
@spec deserialize(map()) :: OperatorProfile.t()
@spec safe_atom(term()) :: atom()
```

## Ordering

1. Create new modules first (no callers yet — safe)
2. Create tests for new modules
3. Modify callers one at a time to delegate
4. Create tests for in-place functions
5. Run full suite to verify no regressions
