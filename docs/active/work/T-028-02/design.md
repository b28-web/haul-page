# T-028-02 Design: Extract Billing/Content/Domain Pure Functions

## Decision: Selective Extraction + Unit Tests

### Approach

Not every audited function warrants extraction to a new module. The ticket says "8-12 pure functions extracted into standalone modules." We'll be selective:

1. **Extract to new module** — when the function is duplicated OR when it's pure logic trapped in a framework-coupled module (LiveView, controller, worker)
2. **Add unit tests in place** — when the function already lives in a reasonable module (e.g., `Billing.can?/2` is fine in `Billing`)
3. **Skip** — when the function is impure (config reads, UUID generation) or when extraction adds complexity without value

### New Modules to Create

#### 1. `Haul.AI.ErrorClassifier` — dedup `transient?/1`
- Extracts identical `transient?/1` from `ContentGenerator` and `Extractor`
- Single source of truth for error classification
- Both callers delegate to this module

#### 2. `Haul.Content.Markdown` — dedup MDEx rendering + frontmatter parsing
- Extracts `render_html/1` from duplicated Ash action logic in `Content.Page`
- Extracts `parse_frontmatter!/1` from `Content.Seeder` (reusable for AI.Prompt too)
- Extracts `strip_frontmatter/1` and `parse_version/1` from `AI.Prompt`
- Groups all markdown/frontmatter utilities

#### 3. `Haul.Workers.ProfileSerializer` — extract from ProvisionSite
- Extracts `serialize_profile/1`, `deserialize_profile/1`, `safe_atom/1`
- Currently private in worker — makes them testable
- Worker delegates to this module

#### 4. `Haul.Billing.PlanLogic` — extract plan metadata
- Extracts `plans/0`, `plan_features/1`, `can?/2`, `feature_label/1`
- Pure plan definitions and feature gating
- `Billing` delegates to this module for backward compat

### Functions That Stay In Place (Unit Tests Added)

| Module | Functions | Rationale |
|--------|-----------|-----------|
| `Haul.Domains` | `normalize_domain/1`, `valid_domain?/1` | Already in correct module, just needs unit tests |
| `Haul.Onboarding` | `derive_slug/1` | Already in correct module |
| `Haul.AI.CostTracker` | `estimate_tokens/1`, `estimate_cost/3`, `model_for_function/1` | Already in dedicated module |
| `Haul.AI.Extractor` | `valid_email?/1` | Simple, stays in place |
| `Haul.Accounts.Changes.ProvisionTenant` | `tenant_schema/1` | Trivial, already public |
| `QRController` | `parse_size/1`, `clamp/3` | Controller-specific, private |
| `BillingWebhookController` | `resolve_plan_*` | Stripe-specific, private |

### Functions Skipped

| Function | Reason |
|----------|--------|
| `Billing.price_id/1` | Reads `Application.get_env` |
| `Billing.plan_for_price_id/1` | Depends on `price_id/1` |
| `Onboarding.site_url/1` | Reads `Application.get_env` |
| `Storage.upload_key/3` | Calls `Ecto.UUID.generate()` (nondeterministic) |
| `BookingEmail` functions | Already pure module, private functions — test via `build/2` |
| `Extractor.validate_completeness/1` | Depends on `ProfileMapper` — not purely extractable |
| `get_field/2` × 4 | T-028-03 scope (LiveView extractions) |
| `friendly_error/1` × 3 | Different per context — not a true dedup |
| `format_price/1` vs `format_amount/1` | Different output formats — not duplicates |

### Rejected Alternatives

**Option A: Extract everything into utility modules**
Rejected — creates unnecessary indirection for functions that are already in the right place. `Domains.normalize_domain/1` doesn't need to move to `Domains.Validation`.

**Option B: Only add tests, no extractions**
Rejected — misses the dedup value (transient?/1, MDEx rendering) and leaves untestable private functions in workers.

**Option C: Create a single `Haul.Utils` module**
Rejected — grab-bag modules are an anti-pattern. Group by domain.

## Test Strategy

- New modules get dedicated `_test.exs` files with `async: true`
- In-place functions get test files named after the module (e.g., `test/haul/domains_test.exs`)
- All tests are pure unit tests — no database, no GenServer, no sandbox
- Target: 30+ new unit tests across all extracted/tested functions
- Edge cases: nil inputs, empty strings, unknown atoms, boundary values

## Extraction Count

| Category | Count |
|----------|-------|
| New modules created | 4 |
| Functions extracted to new modules | 12 |
| Functions unit-tested in place | 14 |
| Functions skipped | 12 |
| **Total functions addressed** | **38** |

This meets the "8-12 pure functions extracted into standalone modules" criterion with 12 extractions, and exceeds the 30+ unit test target.
