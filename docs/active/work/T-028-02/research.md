# T-028-02 Research: Extract Billing/Content/Domain Pure Functions

## Scope

T-028-02 covers items 1–29 and 49–56 from the T-028-01 audit — non-LiveView pure functions in domain modules, controllers, and workers. LiveView extractions are deferred to T-028-03.

## Extraction Candidates by Module

### 1. Billing (6 functions, `lib/haul/billing.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `can?/2` | 62 | Yes | Feature gate: checks plan includes feature |
| `plan_features/1` | 71 | Yes | Map lookup in `@feature_matrix` |
| `plans/0` | 78 | Yes | Returns hardcoded plan definitions |
| `price_id/1` | 95 | No | Reads `Application.get_env` — keep in place |
| `plan_for_price_id/1` | 104 | No | Depends on `price_id/1` — keep in place |
| `feature_label/1` | 119 | Yes | Map lookup in `@feature_labels` |

4 pure functions extractable. `price_id/1` and `plan_for_price_id/1` read config — stay in `Billing`.

### 2. Domains (2 functions, `lib/haul/domains.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `normalize_domain/1` | 24 | Yes | String pipeline: strip protocol, downcase |
| `valid_domain?/1` | 44 | Yes | Regex validation + dot check |

Both pure, tested only through LiveView integration tests.

### 3. Onboarding (2 functions, `lib/haul/onboarding.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `derive_slug/1` | 103 | Yes | Name → URL-safe slug |
| `site_url/1` | 111 | No | Reads `Application.get_env` — keep in place |

1 pure function extractable.

### 4. AI.CostTracker (3 functions, `lib/haul/ai/cost_tracker.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `estimate_tokens/1` | 96 | Yes | `max(1, div(String.length(text), 4))` |
| `estimate_cost/3` | 105 | Yes | Decimal math with pricing map |
| `model_for_function/1` | 126 | Yes | Static map lookup |

All 3 pure. Already in a dedicated module — these stay but get unit tests.

### 5. AI.Extractor (3 functions, `lib/haul/ai/extractor.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `valid_email?/1` | 54 | Yes | Regex validation |
| `validate_completeness/1` | 40 | Partial | Calls `ProfileMapper.missing_fields/1` |
| `transient?/1` | 67 | Yes | Error classification — duplicated in ContentGenerator |

### 6. AI.ContentGenerator (1 function, `lib/haul/ai/content_generator.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `transient?/1` | 151 | Yes | Identical to Extractor copy — dedup target |

### 7. AI.Prompt (2 functions, `lib/haul/ai/prompt.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `strip_frontmatter/1` | 46 | Yes | Regex extraction |
| `parse_version/1` | 53 | Yes | YAML version extraction |

### 8. Content.Seeder (2 functions, `lib/haul/content/seeder.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `parse_frontmatter!/1` | 175 | Yes | YAML frontmatter parser (uses YamlElixir) |
| `atomize/1` | 210 | Yes | String keys → atom keys (private) |

### 9. Content.Page — MDEx rendering (duplicated)

Identical `MDEx.to_html!` call in `:draft` (line 86) and `:edit` (line 98) Ash actions. Both use `extension: [table: true, footnotes: true, strikethrough: true]`.

### 10. Storage (1 function, `lib/haul/storage.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `upload_key/3` | 37 | Impure | Calls `Ecto.UUID.generate()` — nondeterministic. Keep in place. |

### 11. ProvisionTenant (1 function, `lib/haul/accounts/changes/provision_tenant.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `tenant_schema/1` | 22 | Yes | `"tenant_#{slug}"` — trivial, already public |

### 12. BookingEmail (6 functions, `lib/haul/notifications/booking_email.ex`)

Already a pure module. Needs unit tests, not extraction. All functions are private — testing requires calling the public `build/2` API.

### 13. QRController (2 functions, `lib/haul_web/controllers/qr_controller.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `parse_size/1` | 44 | Yes | String → clamped int, default 300 |
| `clamp/3` | 53 | Yes | Min/max bounds |

### 14. BillingWebhookController (3 functions)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `resolve_plan_from_session/1` | 232 | Partial | Calls `Billing.plan_for_price_id/1` (config-dependent) |
| `resolve_plan_from_line_items/1` | 248 | Partial | Same dependency |
| `resolve_plan_from_subscription/1` | 259 | Partial | Same dependency |

### 15. ProvisionSite worker (3 functions, `lib/haul/workers/provision_site.ex`)

| Function | Line | Pure | Notes |
|----------|------|------|-------|
| `serialize_profile/1` | 79 | Yes | Struct → map |
| `deserialize_profile/1` | 100 | Yes | Map → struct |
| `safe_atom/1` | 121 | Yes | String → atom with fallback |

### 16. Cross-module duplications

- **`get_field/2`** × 4 copies (booking_live, payment_live, scan_live, page_controller) — identical
- **`friendly_error/1`** × 3 copies — similar but different max sizes/messages per context
- **`format_price/1`** vs **`format_amount/1`** — different formatting (monthly vs cents display)

## Key Observations

1. **`friendly_error/1` is NOT a dedup candidate** — each context has different file size limits and messages. These are intentionally different.
2. **`format_price/1` and `format_amount/1` are NOT duplicates** — different output formats ($X/mo vs $X.XX).
3. **`get_field/2` is the only true 1:1 dedup** across 4 files but is scope for T-028-03 (LiveView extractions).
4. **`upload_key/3`** is impure (UUID generation) — skip extraction.
5. **`site_url/1`** and **`price_id/1`** read config — skip extraction.
6. **BookingEmail** is already well-structured — add unit tests only.
7. **BillingWebhookController resolve_plan_*** depend on config-reading `plan_for_price_id` — can still extract and test with config setup.
8. **`transient?/1`** is the cleanest dedup — identical in 2 files.
