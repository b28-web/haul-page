# T-018-02 Research: Profile Types

## Scope

Define BAML types for operator profiles and a mapping module (`Haul.AI.ProfileMapper`) that converts BAML output → Ash resource changesets.

## Existing Infrastructure (from T-018-01)

### BAML Setup
- `baml/main.baml` — single file with Anthropic client config + demo `ExtractName` function
- `baml_elixir` 0.2.0 — Rust NIF, precompiled binaries, no Rust toolchain needed
- BAML source compiled at runtime by NIF

### AI Adapter Layer
- `Haul.AI` behaviour — `call_function(name, args) :: {:ok, map()} | {:error, any()}`
- `Haul.AI.Sandbox` — fixture responses for dev/test (pattern matches on function name)
- `Haul.AI.Baml` — real API calls via `BamlElixir.Client`
- Config: sandbox in dev/test, BAML adapter in prod when `ANTHROPIC_API_KEY` present

### Target Ash Resources

**Company** (`lib/haul/accounts/company.ex`):
- `name` (string, required) — business name
- `slug` (string, required) — auto-generated
- No `owner_name`, `years_in_business`, or `differentiators` fields exist

**SiteConfig** (`lib/haul/content/site_config.ex`):
- `business_name` (string, required)
- `phone` (string, required)
- `email` (string, optional)
- `tagline` (string, optional)
- `service_area` (string, optional)
- `address` (string, optional)
- `coupon_text`, `meta_description`, `primary_color`, `logo_url` — all optional
- Actions: `:create_default` (accepts all fields), `:edit`
- Multitenancy: `:context` strategy
- Code interface: `SiteConfig.current()`, `SiteConfig.edit()`

**Service** (`lib/haul/content/service.ex`):
- `title` (string, required)
- `description` (string, required)
- `icon` (string, required)
- `sort_order` (integer, required, default: 0)
- `active` (boolean, required, default: true)
- No `category` attribute exists
- Actions: `:add` (create), `:edit`, `:destroy`
- Multitenancy: `:context` strategy

### Content Domain (`lib/haul/content.ex`)
- Ash domain aggregating: SiteConfig, Service, GalleryItem, Endorsement, Page + Version resources
- All resources tenant-scoped

## Gap Analysis: BAML Types vs Ash Resources

The ticket's acceptance criteria define these BAML fields:

| BAML Field | Target Resource | Target Attribute | Exists? |
|---|---|---|---|
| `business_name` | Company + SiteConfig | `.name` / `.business_name` | ✅ |
| `owner_name` | — | — | ❌ No attribute |
| `phone` | SiteConfig | `.phone` | ✅ |
| `email` | SiteConfig | `.email` | ✅ |
| `service_area` | SiteConfig | `.service_area` | ✅ |
| `tagline` | SiteConfig | `.tagline` | ✅ |
| `years_in_business` | — | — | ❌ No attribute |
| `services[].name` | Service | `.title` | ✅ |
| `services[].description` | Service | `.description` | ✅ |
| `services[].category` | Service | — | ❌ No attribute |
| `differentiators` | — | — | ❌ No attribute |

### Fields with no current home
1. **`owner_name`** — Not on Company or SiteConfig. Could add to SiteConfig.
2. **`years_in_business`** — Not anywhere. Could add to SiteConfig.
3. **`differentiators`** — List of strings, no resource for this. Could store on SiteConfig as JSON/array.
4. **`category`** on Service — Service has no category enum. Could add.

### Key Decision Point
The ticket says "Types map cleanly to existing Ash resources." The gap fields (`owner_name`, `years_in_business`, `differentiators`, `category`) either:
- (A) Need schema migrations on existing resources, or
- (B) Get stored only in the BAML/mapper layer as metadata that doesn't persist

Given this is an AI onboarding pipeline (S-018 → S-019 → S-020), the extracted profile feeds into content generation. Fields like `owner_name` and `differentiators` inform content but may not need their own DB columns — they can be passed through the pipeline as transient data.

However, `category` on Service is useful for the domain model regardless of AI. And `owner_name` on SiteConfig makes sense for display.

## Adapter Pattern for Testing

The sandbox adapter currently pattern-matches function names. For `ExtractOperatorProfile`, it needs a fixture that returns a full `OperatorProfile` map. This is straightforward — add another clause to `Haul.AI.Sandbox.call_function/2`.

## Downstream Dependencies

- **T-018-03** (extraction) will call a BAML function that uses OperatorProfile type
- **T-018-04** (tests) will test the full extraction pipeline
- **T-019-*/** (conversational onboarding) will use ProfileMapper to persist extracted profiles
- **T-020-*/** (content generation) will use profile data for AI content generation

## Constraints

- BAML types are defined in `.baml` files, parsed at runtime by NIF
- Elixir-side structs must mirror BAML types for clean mapping
- ProfileMapper must produce Ash-compatible changesets (maps with atom keys matching resource attributes)
- Must handle partial profiles (LLM may not extract every field)
- Sandbox must return realistic fixture data for testing
