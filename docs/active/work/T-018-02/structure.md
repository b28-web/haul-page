# T-018-02 Structure: Profile Types

## Files Created

### 1. `baml/types/operator_profile.baml`
BAML type definitions: `OperatorProfile`, `ServiceOffering`, `ServiceCategory` enum.
No BAML function here — just types. T-018-03 will add the extraction function.

### 2. `lib/haul/ai/operator_profile.ex`
Module: `Haul.AI.OperatorProfile`

Elixir struct mirroring BAML types:
- `defstruct` with all OperatorProfile fields
- Nested `Haul.AI.OperatorProfile.ServiceOffering` with `defstruct`
- `@type t()` typespecs
- `from_baml(map) :: t()` — converts BAML string-keyed map to struct
- `@service_categories` — atom list matching BAML enum

### 3. `lib/haul/ai/profile_mapper.ex`
Module: `Haul.AI.ProfileMapper`

Public functions:
- `to_company_attrs(profile) :: map()` — extracts Company-relevant fields
- `to_site_config_attrs(profile) :: map()` — extracts SiteConfig-relevant fields
- `to_service_attrs_list(profile) :: [map()]` — converts ServiceOffering list to Service attr maps
- `missing_fields(profile) :: [atom()]` — returns list of required but nil fields

### 4. `test/haul/ai/operator_profile_test.exs`
Tests for `from_baml/1`:
- Full profile map → correct struct with nested ServiceOfferings
- Partial map (missing optional fields) → struct with nils
- Invalid category string → defaults to `:other`

### 5. `test/haul/ai/profile_mapper_test.exs`
Tests for ProfileMapper:
- Valid profile → correct Company attrs
- Valid profile → correct SiteConfig attrs
- Valid profile → correct Service attrs list with mapped field names
- Partial profile → `missing_fields/1` returns correct list
- Empty services → returns empty list

### 6. `priv/repo/tenant_migrations/TIMESTAMP_add_owner_name_to_site_config.exs`
Adds `owner_name` string column (nullable) to `site_configs` table.

### 7. `priv/repo/tenant_migrations/TIMESTAMP_add_category_to_services.exs`
Adds `category` string column (nullable) to `services` table.

## Files Modified

### 8. `lib/haul/content/site_config.ex`
- Add `attribute :owner_name, :string` (optional)

### 9. `lib/haul/content/service.ex`
- Add `attribute :category, :atom` with constraints `one_of: [:junk_removal, :cleanouts, :yard_waste, :repairs, :assembly, :moving_help, :other]`
- Make it optional (allow_nil)

### 10. `lib/haul/ai/sandbox.ex`
- Add `"ExtractOperatorProfile"` clause returning fixture OperatorProfile map

### 11. `baml/main.baml`
- Add `import` or include for types/operator_profile.baml (if BAML supports includes), OR inline the types in main.baml

## File Organization

```
baml/
  main.baml                          # existing — add types here (BAML doesn't support multi-file well in baml_elixir)
lib/haul/ai/
  operator_profile.ex                # NEW — struct + from_baml
  profile_mapper.ex                  # NEW — struct → Ash attr maps
  sandbox.ex                         # MODIFY — add fixture
  baml.ex                            # existing — no changes
lib/haul/content/
  site_config.ex                     # MODIFY — add owner_name
  service.ex                         # MODIFY — add category
test/haul/ai/
  operator_profile_test.exs          # NEW
  profile_mapper_test.exs            # NEW
priv/repo/tenant_migrations/
  TIMESTAMP_add_owner_name_to_site_config.exs  # NEW
  TIMESTAMP_add_category_to_services.exs       # NEW
```

## Module Boundaries

- `Haul.AI.OperatorProfile` — data structure only, no side effects
- `Haul.AI.ProfileMapper` — pure transformation, no DB access, no side effects
- Schema changes to SiteConfig/Service are additive (new optional attrs)
- Sandbox change is additive (new pattern match clause)

## Ordering

1. Schema migrations + resource attribute additions (SiteConfig, Service)
2. BAML type definitions
3. OperatorProfile struct + from_baml
4. ProfileMapper
5. Sandbox fixture
6. Tests
