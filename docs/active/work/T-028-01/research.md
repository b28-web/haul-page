# T-028-01 Research: Logic Audit

## Scope

Surveyed all modules in `lib/haul/` (domain), `lib/haul_web/live/` (LiveViews), `lib/haul_web/controllers/` (controllers), and `lib/haul/workers/` (workers) for extractable pure functions and embedded business logic.

## Codebase Topology

### Domain Modules (`lib/haul/`)

**Already well-extracted (pure function modules):**
- `Haul.AI.EditClassifier` — pure regex-based message classification (`classify/1`)
- `Haul.AI.ProfileMapper` — pure struct-to-attrs transformations (`to_company_attrs/1`, `to_site_config_attrs/1`, `to_service_attrs_list/1`, `missing_fields/1`, `reject_nils/1`)
- `Haul.AI.OperatorProfile` — pure BAML output parsing (`from_baml/1`, `parse_services/1`)
- `Haul.Notifications.BookingEmail` — pure template building (6 functions, all string interpolation)
- `Haul.Notifications.BookingSMS` — pure SMS message construction

**Mixed modules with extractable pure logic:**
- `Haul.Billing` — `can?/2`, `plan_features/1`, `plans/0`, `price_id/1`, `plan_for_price_id/1`, `feature_label/1` are all pure lookups
- `Haul.Domains` — `normalize_domain/1`, `valid_domain?/1` pure; `verify_dns/2` has inet_res dependency
- `Haul.Onboarding` — `derive_slug/1`, `site_url/1`, `validate_password_match/2`, `validate_password_length/1`, `validate_required/2` are pure
- `Haul.AI.CostTracker` — `estimate_tokens/1`, `estimate_cost/3`, `model_for_function/1`, `sum_costs/1` are pure Decimal math
- `Haul.AI.Extractor` — `valid_email?/1`, `validate_completeness/1`, `transient?/1` are pure
- `Haul.AI.ContentGenerator` — `transient?/1` duplicated from Extractor
- `Haul.AI.Prompt` — `strip_frontmatter/1`, `parse_version/1` are pure regex
- `Haul.Content.Seeder` — `parse_frontmatter!/1`, `atomize/1` are pure parsing
- `Haul.Storage` — `upload_key/3` is pure key generation

**Ash resource inline logic:**
- `Haul.Accounts.Company` — slug derivation in `create_company` action (duplicate of Onboarding logic)
- `Haul.Content.Page` — markdown→HTML conversion duplicated in `draft` and `edit` actions
- `Haul.Accounts.Changes.ProvisionTenant` — `tenant_schema/1` is pure (`"tenant_#{slug}"`)
- `Haul.Operations.Changes.EnqueueNotifications` — worker payload construction

### LiveView Modules (`lib/haul_web/live/`)

**Display formatting (pure):**
- `BillingLive` — `plan_rank/1`, `format_price/1`, `days_until_downgrade/1`
- `PaymentLive` — `format_amount/1` (duplicate of billing format logic)
- `EndorsementsLive` — `source_label/1`, `star_display/1`
- `OnboardingLive` — `step_title/1`
- `AccountsLive` — `plan_badge_class/1`, `sort_indicator/3`, `toggle_dir/1`

**Data transformations (pure):**
- `BookingLive` — `merge_preferred_dates/1`
- `ChatLive` — `build_transcript/1`, `append_to_last_assistant/2`, `has_assistant_content?/1`, `deep_to_map/1`
- `AccountsLive` — `filter_companies/2`, `sort_companies/3`
- `GalleryLive` — `extract_key/1`, `next_sort_order/1`

**Duplicated helpers:**
- `get_field/2` appears in BookingLive, PaymentLive, ScanLive, PageController (4 copies)
- `friendly_error/1` / `upload_error_to_string/1` appears in BookingLive, GalleryLive, OnboardingLive (3 copies)

### Controllers (`lib/haul_web/controllers/`)

- `QRController` — `parse_size/1`, `clamp/3` are pure parameter validation
- `BillingWebhookController` — `resolve_plan_from_session/1`, `resolve_plan_from_line_items/1`, `resolve_plan_from_subscription/1` are pure Stripe payload parsing

### Workers (`lib/haul/workers/`)

- `ProvisionSite` — `serialize_profile/1`, `deserialize_profile/1`, `safe_atom/1` are pure serialization
- Workers delegate message construction to Notification modules (already pure)
- `ProvisionCert` — polling logic tightly coupled to external calls

## Test Coverage Patterns

**Well-tested via unit tests:** EditClassifier (via EditApplierTest), ProfileMapper (indirect)
**Integration-only:** BookingEmail templates, Billing feature gates, CostTracker calculations, webhook payload parsing
**No tests:** Prompt parsing, QR parameter validation, ProvisionSite serialization, most LiveView helper functions

## Key Observations

1. **Notification modules are the gold standard** — BookingEmail/BookingSMS are already pure, just lack isolated unit tests
2. **Slug derivation is duplicated** — Company resource and Onboarding module both derive slugs independently
3. **`get_field/2` is copy-pasted 4 times** — trivial but symptomatic
4. **Upload error formatting duplicated 3 times** — BookingLive, GalleryLive, OnboardingLive
5. **`transient?/1` duplicated** — Extractor and ContentGenerator have identical implementations
6. **Markdown rendering duplicated** — Page resource has same MDEx call in both `draft` and `edit` actions
7. **Price formatting split** — BillingLive and PaymentLive format cents→dollars independently
