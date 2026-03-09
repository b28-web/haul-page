# T-018-02 Design: Profile Types

## Decision 1: Where do gap fields live?

### Option A: Add all fields to Ash resources via migrations
- Add `owner_name`, `years_in_business`, `differentiators` to SiteConfig
- Add `category` enum to Service
- Pro: Everything persists, queryable, consistent
- Con: Migrations for fields that may only matter to AI pipeline

### Option B: Transient-only — gap fields exist in BAML/Elixir structs but don't persist
- ProfileMapper maps what it can, drops `owner_name`, `years_in_business`, `differentiators`
- Con: Loses data the LLM extracted; downstream tickets (content generation) need this info

### Option C: Persist useful fields, skip truly transient ones ✅ CHOSEN
- **Add to SiteConfig**: `owner_name` (string, optional) — useful for display and content gen
- **Add to Service**: `category` (atom enum, optional) — useful for domain model
- **Keep transient**: `years_in_business`, `differentiators` — these feed content generation prompts but don't need DB columns. The `OperatorProfile` Elixir struct holds them; downstream pipeline passes them through.

**Rationale**: `owner_name` and `category` have independent value beyond AI. `years_in_business` and `differentiators` are content generation inputs only — storing them as a JSON blob on SiteConfig would add complexity for minimal benefit. The extraction pipeline (T-018-03 → T-019/T-020) passes the full struct through.

## Decision 2: Elixir struct design

### Option A: Single flat struct
```elixir
defmodule Haul.AI.OperatorProfile do
  defstruct [:business_name, :owner_name, :phone, :email, ...]
end
```
- Pro: Simple
- Con: `services` would be a list of plain maps

### Option B: Nested structs mirroring BAML types ✅ CHOSEN
```elixir
defmodule Haul.AI.OperatorProfile do
  defstruct [...]

  defmodule ServiceOffering do
    defstruct [:name, :description, :category]
  end
end
```
- Pro: Type-safe, mirrors BAML contract, clear validation boundaries
- Con: Slightly more code

**Rationale**: The BAML output is already typed. Mirroring with Elixir structs gives us pattern matching and clear documentation of the contract. `ServiceOffering` nests inside `OperatorProfile` since it's only used in this context.

## Decision 3: ProfileMapper approach

### Option A: Return Ash changesets directly
- Con: Ash changesets need actor context, tenant, etc. — too coupled

### Option B: Return plain maps ready for Ash action input ✅ CHOSEN
- `to_company_attrs/1` → `%{name: "...", ...}`
- `to_site_config_attrs/1` → `%{business_name: "...", phone: "...", ...}`
- `to_service_attrs_list/1` → `[%{title: "...", description: "...", ...}, ...]`
- `missing_fields/1` → `[:phone, :email]` (required fields not extracted)
- Pro: Clean separation — mapper handles data transformation, caller handles persistence
- Con: None significant

**Rationale**: Ash actions accept plain maps. The mapper shouldn't know about actors, tenants, or persistence context. Callers (onboarding flow, tests) apply their own context.

## Decision 4: Parsing BAML output → Elixir structs

BAML returns maps with string keys (JSON-parsed). Need a `from_baml/1` function that:
1. Converts string keys to atom keys
2. Constructs `OperatorProfile` and nested `ServiceOffering` structs
3. Converts `category` string ("JUNK_REMOVAL") to atom (`:junk_removal`)
4. Handles missing optional fields gracefully (nil, not crash)

## Decision 5: Schema changes

Two small migrations:
1. Add `owner_name` (string, nullable) to SiteConfig — tenant migration
2. Add `category` (string, nullable) to Service — tenant migration

Both are optional fields, no data migration needed. Existing records get `nil`.

## Decision 6: Sandbox fixture

Add `"ExtractOperatorProfile"` clause to `Haul.AI.Sandbox` returning a realistic fixture map with all fields populated. This lets tests exercise the full mapping pipeline without LLM calls.

## Architecture Summary

```
baml/types/operator_profile.baml     ← BAML type definitions
    ↓ (runtime compilation by NIF)
BamlElixir → Haul.AI.call_function   ← returns map with string keys
    ↓
Haul.AI.OperatorProfile.from_baml/1  ← parses to Elixir struct
    ↓
Haul.AI.ProfileMapper                ← converts struct → Ash-ready attr maps
    ↓
Caller applies tenant + actor context and calls Ash actions
```
