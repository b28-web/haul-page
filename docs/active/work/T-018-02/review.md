# T-018-02 Review: Profile Types

## Summary

Defined the BAML type system for operator profiles and built the Elixir mapping layer. The BAML types serve as the contract between LLM output and Ash resources. The ProfileMapper converts parsed profiles into attribute maps suitable for Ash actions.

## Files Created (7)

| File | Purpose |
|---|---|
| `baml/main.baml` (modified) | Added OperatorProfile, ServiceOffering, ServiceCategory BAML types |
| `lib/haul/ai/operator_profile.ex` | Elixir struct + `from_baml/1` parser |
| `lib/haul/ai/profile_mapper.ex` | Pure mapping: profile → Company/SiteConfig/Service attrs |
| `priv/repo/tenant_migrations/…_add_owner_name_to_site_configs.exs` | Schema: owner_name on site_configs |
| `priv/repo/tenant_migrations/…_add_category_to_services.exs` | Schema: category on services |
| `test/haul/ai/operator_profile_test.exs` | 6 tests for struct parsing |
| `test/haul/ai/profile_mapper_test.exs` | 8 tests for mapping logic |

## Files Modified (3)

| File | Change |
|---|---|
| `lib/haul/content/site_config.ex` | Added `owner_name` attribute, updated action accept lists |
| `lib/haul/content/service.ex` | Added `category` atom attribute with enum constraint, updated action accept lists |
| `lib/haul/ai/sandbox.ex` | Added `ExtractOperatorProfile` fixture clause |

## Test Coverage

- **14 new tests** (6 OperatorProfile + 8 ProfileMapper), all passing
- **520 total tests**, 0 failures — no regressions
- Tests cover: full profile parsing, partial profiles, nil handling, unknown categories, field name mapping, icon assignment, missing field detection

### What's tested
- `from_baml/1`: full map, partial map, nil category, unknown category
- `to_company_attrs/1`: field extraction, nil omission
- `to_site_config_attrs/1`: all 6 mapped fields, nil omission
- `to_service_attrs_list/1`: field name mapping (name→title), icon assignment by category, sort_order auto-increment, nil description→empty string, empty list
- `missing_fields/1`: complete profile, partial profile, empty profile

### What's not tested (intentional)
- Integration with Ash actions (covered by T-018-03/T-018-04)
- BAML runtime compilation (covered by baml_elixir itself)
- Real LLM calls (sandbox pattern — production adapter tested separately)

## Design Decisions

1. **Transient fields**: `years_in_business` and `differentiators` exist in the Elixir struct but don't persist to DB. They feed downstream content generation (T-020) without requiring schema changes.

2. **Persisted fields**: `owner_name` on SiteConfig and `category` on Service have independent domain value beyond AI onboarding.

3. **Icon mapping**: ProfileMapper assigns FontAwesome icons based on service category. This avoids requiring the LLM to know icon systems.

4. **Nil rejection**: Mapper functions omit nil values from output maps so Ash actions receive only explicitly set fields.

## Open Concerns

- **None blocking.** All acceptance criteria met.
- The `category` enum on Service is additive — existing services get `nil` category which is fine (optional field).
- Downstream ticket T-018-03 will add the BAML extraction function that uses these types.
- Content generation (T-020) will need the transient fields (`years_in_business`, `differentiators`) passed through the pipeline — the OperatorProfile struct carries them.
