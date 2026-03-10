# T-028-01 Audit: Extractable Pure Functions

## Summary

| Category | Count |
|----------|-------|
| Pure functions | 38 |
| Logic with DB reads | 3 |
| Tightly coupled | 4 |
| **Total candidates** | **45** |

Duplicated functions found: 3 patterns (get_field ×4, friendly_error ×3, transient? ×2)

---

## Ash Resources & Domain Modules

### `Haul.Billing` — Feature gates and plan lookups

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 1 | `can?/2` | 62 | Checks if company plan includes a feature | Pure | None | Trivial | None |
| 2 | `plan_features/1` | 71 | Returns feature list for a plan atom | Pure | None | Trivial | None |
| 3 | `plans/0` | 78 | Returns all plan definitions with metadata | Pure | None | Trivial | None |
| 4 | `price_id/1` | 95 | Looks up Stripe price ID for plan from config | Pure | None | Trivial | Application.get_env |
| 5 | `plan_for_price_id/1` | 104 | Reverse lookup: price ID → plan atom | Pure | None | Trivial | Calls `plans/0` |
| 6 | `feature_label/1` | 119 | Human-readable name for a feature atom | Pure | None | Trivial | None |

**Downstream:** T-028-02

### `Haul.Domains` — Domain validation

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 7 | `normalize_domain/1` | 24 | Strips protocol, path, downcases domain string | Pure | Integration-only | Trivial | None |
| 8 | `valid_domain?/1` | 44 | Validates domain format via regex | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-02

### `Haul.Onboarding` — Registration helpers

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 9 | `derive_slug/1` | 103 | Converts business name to URL-safe slug | Pure | Integration-only | Trivial | None |
| 10 | `site_url/1` | 111 | Builds full site URL from slug | Pure | Integration-only | Trivial | Application.get_env |

**Downstream:** T-028-02

### `Haul.AI.CostTracker` — Token estimation

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 11 | `estimate_tokens/1` | 96 | Estimates token count from text (~4 chars/token) | Pure | None | Trivial | None |
| 12 | `estimate_cost/3` | 105 | Calculates USD cost for model+tokens via Decimal | Pure | None | Trivial | Decimal |
| 13 | `model_for_function/1` | 126 | Maps BAML function name to model string | Pure | None | Trivial | None |

**Downstream:** T-028-02

### `Haul.AI.Extractor` — Profile validation

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 14 | `valid_email?/1` | 54 | Validates email format via regex | Pure | None | Trivial | None |
| 15 | `validate_completeness/1` | 40 | Checks which required profile fields are missing | Pure | None | Trivial | None |

**Downstream:** T-028-02

### `Haul.AI.Prompt` — Markdown parsing

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 16 | `strip_frontmatter/1` | 46 | Removes YAML frontmatter from markdown string | Pure | None | Trivial | None |
| 17 | `parse_version/1` | 53 | Extracts version string from YAML frontmatter | Pure | None | Trivial | None |

**Downstream:** T-028-02

### `Haul.AI.ContentGenerator` / `Haul.AI.Extractor` — Error classification (DUPLICATED)

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 18 | `transient?/1` | content_generator:151, extractor:67 | Classifies error tuples as transient (timeout, rate limit, 5xx) | Pure | None | Trivial | None |

Identical implementation in two files. Should be extracted to shared module.

**Downstream:** T-028-02

### `Haul.Content.Seeder` — YAML/frontmatter parsing

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 19 | `parse_frontmatter!/1` | 175 | Parses YAML frontmatter from markdown file content | Pure | None | Trivial | YamlElixir |
| 20 | `atomize/1` | 210 | Converts string map keys to atom keys | Pure | None | Trivial | None |

**Downstream:** T-028-02

### `Haul.Content.Page` — Markdown rendering (DUPLICATED)

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 21 | MDEx render logic | draft:86, edit:98 | Converts markdown body to HTML with extensions | Pure | Integration-only | Moderate | MDEx |

Same MDEx call duplicated in two Ash actions. Should be extracted to a shared function.

**Downstream:** T-028-02

### `Haul.Storage` — Key generation

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 22 | `upload_key/3` | 37 | Generates unique storage key from tenant+prefix+filename | Pure | None | Trivial | Ecto.UUID |

**Downstream:** T-028-02

### `Haul.Accounts.Changes.ProvisionTenant` — Schema naming

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 23 | `tenant_schema/1` | 22 | Derives Postgres schema name from slug | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-02

### `Haul.Notifications.BookingEmail` — Email template building

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 24 | `operator_alert_text/2` | 48 | Builds plain-text operator alert email body | Pure | Integration-only | Trivial | None |
| 25 | `customer_confirmation_text/2` | 63 | Builds plain-text customer confirmation body | Pure | Integration-only | Trivial | None |
| 26 | `operator_alert_html/2` | 82 | Builds HTML operator alert with table | Pure | Integration-only | Trivial | None |
| 27 | `customer_confirmation_html/2` | 116 | Builds HTML customer confirmation | Pure | Integration-only | Trivial | None |
| 28 | `html_layout/2` | 141 | Wraps content in email HTML template | Pure | Integration-only | Trivial | None |
| 29 | `escape/1` | 167 | HTML-escapes string values | Pure | Integration-only | Trivial | None |

Already pure module — needs dedicated unit tests, not extraction.

**Downstream:** T-028-02

---

## LiveView Modules

### `BillingLive` — Price formatting and plan logic

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 30 | `plan_rank/1` | 337 | Maps plan atom to numeric rank for comparison | Pure | Integration-only | Trivial | None |
| 31 | `format_price/1` | 351 | Converts cents integer to "$X.XX" string | Pure | Integration-only | Trivial | None |
| 32 | `days_until_downgrade/1` | 362 | Calculates remaining grace days from DateTime | Pure | Integration-only | Trivial | DateTime |

**Downstream:** T-028-03

### `PaymentLive` — Amount formatting (DUPLICATE of BillingLive)

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 33 | `format_amount/1` | 121 | Converts cents to "$X.XX" — same logic as format_price | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

### `EndorsementsLive` — Display formatting

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 34 | `source_label/1` | 165 | Maps endorsement source atom to display string | Pure | Integration-only | Trivial | None |
| 35 | `star_display/1` | 171 | Renders star rating as filled/empty symbols | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

### `AccountsLive` (admin) — Filtering, sorting, display

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 36 | `filter_companies/2` | 177 | Case-insensitive search on slug and name | Pure | Integration-only | Trivial | None |
| 37 | `sort_companies/3` | 188 | Sorts company list by field and direction | Pure | Integration-only | Trivial | None |
| 38 | `toggle_dir/1` | 202 | Toggles :asc ↔ :desc | Pure | Integration-only | Trivial | None |
| 39 | `sort_indicator/3` | 205 | Returns ↑/↓/"" arrow for table header | Pure | Integration-only | Trivial | None |
| 40 | `plan_badge_class/1` | 209 | Maps plan atom to CSS class string | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

### `ChatLive` — Transcript building

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 41 | `build_transcript/1` | 841 | Constructs plaintext transcript from message list | Pure | Integration-only | Trivial | None |
| 42 | `append_to_last_assistant/2` | 848 | Appends streamed text to last assistant message | Pure | Integration-only | Trivial | None |
| 43 | `has_assistant_content?/1` | 859 | Checks if last message is non-empty assistant | Pure | Integration-only | Trivial | None |
| 44 | `deep_to_map/1` | 926 | Recursively converts struct tree to plain maps | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

### `BookingLive` — Form params

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 45 | `merge_preferred_dates/1` | 76 | Collapses three date params into single array | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

### `GalleryLive` — Upload helpers

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 46 | `extract_key/1` | 218 | Parses storage URL to extract object key | Pure | Integration-only | Trivial | URI |
| 47 | `next_sort_order/1` | 261 | Computes max sort_order + 1 from item list | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

### `OnboardingLive` — Step display

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 48 | `step_title/1` | 394 | Maps step number to description string | Pure | Integration-only | Trivial | None |

**Downstream:** T-028-03

---

## Controllers

### `QRController` — Parameter validation

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 49 | `parse_size/1` | 44 | Parses size param string, validates bounds, defaults 300 | Pure | None | Trivial | None |
| 50 | `clamp/3` | 53 | Clamps value between min/max bounds | Pure | None | Trivial | None |

**Downstream:** T-028-02

### `BillingWebhookController` — Stripe payload parsing

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 51 | `resolve_plan_from_session/1` | 232 | Extracts plan from Stripe checkout session metadata | Pure | Integration-only | Moderate | Billing.plan_for_price_id |
| 52 | `resolve_plan_from_line_items/1` | 248 | Maps Stripe line item price ID to plan | Pure | Integration-only | Moderate | Billing.plan_for_price_id |
| 53 | `resolve_plan_from_subscription/1` | 259 | Extracts plan from subscription items | Pure | Integration-only | Moderate | Billing.plan_for_price_id |

**Downstream:** T-028-02

---

## Workers

### `ProvisionSite` — Profile serialization

| # | Function | Line | Does | Category | Coverage | Difficulty | Dependencies |
|---|----------|------|------|----------|----------|------------|--------------|
| 54 | `serialize_profile/1` | 79 | Converts OperatorProfile struct to map for Oban | Pure | None | Trivial | None |
| 55 | `deserialize_profile/1` | 100 | Reconstructs OperatorProfile from persisted map | Pure | None | Trivial | None |
| 56 | `safe_atom/1` | 121 | Safely converts string to known atom with fallback | Pure | None | Trivial | None |

**Downstream:** T-028-02

---

## Cross-Module Duplications

### `get_field/2` — 4 copies
- `lib/haul_web/live/booking_live.ex:103`
- `lib/haul_web/live/payment_live.ex:118`
- `lib/haul_web/live/scan_live.ex:21`
- `lib/haul_web/controllers/page_controller.ex:40`

Extract to: `HaulWeb.Helpers` or similar shared module.

### `friendly_error/1` / `upload_error_to_string/1` — 3 copies
- `lib/haul_web/live/booking_live.ex:106` (as `friendly_error`)
- `lib/haul_web/live/app/gallery_live.ex:264` (as `friendly_error`)
- `lib/haul_web/live/app/onboarding_live.ex:401` (as `upload_error_to_string`)

Same pattern, slightly different messages. Extract to shared upload error formatter.

### `transient?/1` — 2 identical copies
- `lib/haul/ai/content_generator.ex:151`
- `lib/haul/ai/extractor.ex:67`

Identical implementations. Extract to `Haul.AI.ErrorClassifier` or similar.

### `format_price/1` / `format_amount/1` — 2 copies
- `lib/haul_web/live/app/billing_live.ex:351`
- `lib/haul_web/live/payment_live.ex:121`

Same cents→dollars formatting. Extract to shared formatter.

---

## Priority Ranking (Top 20 by Impact)

| Rank | Function(s) | Why | Category |
|------|-------------|-----|----------|
| 1 | `Billing.can?/2`, `plan_features/1`, `plans/0`, `feature_label/1` | Core feature gating with zero unit tests, used across billing/signup | Pure |
| 2 | `get_field/2` (×4 copies) | Dedup 4 identical copies across LiveViews + controller | Pure |
| 3 | `friendly_error/1` (×3 copies) | Dedup 3 near-identical upload error formatters | Pure |
| 4 | `transient?/1` (×2 copies) | Dedup identical error classifiers in AI modules | Pure |
| 5 | `format_price/1` + `format_amount/1` (×2) | Dedup duplicate cents formatting | Pure |
| 6 | `CostTracker.estimate_tokens/1`, `estimate_cost/3` | Financial calculations with no unit tests | Pure |
| 7 | `Domains.normalize_domain/1`, `valid_domain?/1` | Domain validation tested only through LiveView | Pure |
| 8 | `Onboarding.derive_slug/1` | Slug logic duplicated in Company resource | Pure |
| 9 | `BookingEmail` template functions (6) | 6 pure functions tested only through worker integration | Pure |
| 10 | `AccountsLive.filter_companies/2`, `sort_companies/3` | Reusable list operations tested only via LiveView | Pure |
| 11 | `ChatLive.build_transcript/1`, `append_to_last_assistant/2` | Message list transforms tested only via LiveView | Pure |
| 12 | `BillingWebhookController.resolve_plan_*` (3) | Stripe payload parsing tested only via controller | Pure |
| 13 | `ProvisionSite.serialize_profile/1`, `deserialize_profile/1` | Serialization with no tests at all | Pure |
| 14 | `Prompt.strip_frontmatter/1`, `parse_version/1` | YAML parsing with no tests | Pure |
| 15 | `Extractor.valid_email?/1`, `validate_completeness/1` | Validation with no unit tests | Pure |
| 16 | Content.Page MDEx render (duplicated in 2 actions) | Duplicated markdown rendering in Ash actions | Pure |
| 17 | `GalleryLive.extract_key/1`, `next_sort_order/1` | URL parsing + sort logic, LiveView-only testing | Pure |
| 18 | `QRController.parse_size/1`, `clamp/3` | Parameter validation with no tests | Pure |
| 19 | `BillingLive.days_until_downgrade/1` | Date math tested only via LiveView | Pure |
| 20 | `Seeder.parse_frontmatter!/1`, `atomize/1` | Parsing utils tested only through seeder integration | Pure |

All top 20 are pure functions. The audit found 0 "logic with DB reads" candidates worth extracting — those patterns are already well-separated (adapters call DB, pure functions transform data).

---

## Already Well-Extracted (No Action Needed)

These modules are already clean pure-function modules. They need unit tests but not structural extraction:

- `Haul.AI.EditClassifier` — exemplary pure pattern matching
- `Haul.AI.ProfileMapper` — clean struct→attrs transforms
- `Haul.AI.OperatorProfile` — clean BAML parsing
- `Haul.Notifications.BookingEmail` — pure template building
- `Haul.Notifications.BookingSMS` — pure message construction
