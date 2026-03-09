# T-020-01 Research: Content Generation Functions

## Existing Infrastructure

### BAML Setup
- **File:** `baml/main.baml` — single BAML source compiled by `baml_elixir` NIF at runtime
- **Client:** Anthropic with `claude-sonnet-4-20250514`, API key from env
- **Existing types:** `PersonName`, `ServiceCategory` (enum), `ServiceOffering`, `OperatorProfile`
- **Existing functions:** `ExtractName`, `ExtractOperatorProfile`
- Ticket requires Claude Haiku for cost efficiency — needs a second client definition

### AI Adapter Pattern
- `Haul.AI` behaviour: `call_function(name, args) :: {:ok, map()} | {:error, any()}`
- `Haul.AI.Sandbox` — dev/test adapter with `set_response/2` per-process overrides
- `Haul.AI.Baml` — production adapter using `BamlElixir.Client`
- Config: `:haul, :ai_adapter` selects implementation

### Existing Wrappers
- `Haul.AI.Extractor` — wraps `ExtractOperatorProfile` with retry logic and validation
- `Haul.AI.ProfileMapper` — converts `OperatorProfile` to Ash resource attrs (SiteConfig, Service, etc.)
- Pattern: wrapper module calls `Haul.AI.call_function/2`, parses result into typed struct

### Content Domain Resources (Target Schemas)
Output must conform to these Ash resource schemas:

**SiteConfig** — `meta_description: string` (optional, no length constraint in schema)
**Service** — `title: string`, `description: string`, `icon: string`, `sort_order: integer`, `active: boolean`, `category: atom` (optional, constrained)
**Endorsement** — `customer_name: string`, `quote_text: string`, `star_rating: integer` (1-5), `source: atom`, `date: date`, `featured: boolean`, `active: boolean`, `sort_order: integer`

Note: No "why hire us" or "tagline" Ash resource — these are content for the landing page template, not distinct resources.

### Landing Page Format (from mockup-reference)
The landing page renders:
- Tagline — short marketing line
- Services — each with title, description, icon
- "Why hire us" — bullet points (rendered from differentiators)
- Meta description — SEO `<meta>` tag

The "why hire us" bullets map to the differentiators stored on OperatorProfile. They could be stored as a Page resource (markdown body) or kept in SiteConfig (no field exists yet). The simplest path: return them as a list of strings and let the caller decide storage.

### Sandbox Pattern for Tests
- `Haul.AI.Sandbox.set_response("FunctionName", {:ok, map})` — per-process
- Tests call the sandbox, assert on parsed output structure
- No real LLM calls in default test suite

### Token Logging Requirement
- No existing token logging infrastructure
- `Haul.AI.call_function/2` returns `{:ok, map()}` — no metadata channel
- Logging via `Logger` is the simplest path; structured usage tracking can come later

## Key Constraints

1. **BAML functions must use typed output** — BAML enforces structured output via `{{ ctx.output_format }}`
2. **Content must pass Ash validations** — Service descriptions must be non-empty strings, meta_description has no max-length constraint in schema but ticket says ≤160 chars
3. **Cost efficiency** — ticket specifies Claude Haiku, need a second BAML client (`AnthropicHaiku`)
4. **Sandbox must support all new functions** — dev/test should never call real LLM
5. **OperatorProfile is the input** — all generation functions receive profile data, not raw transcript

## Files Relevant to This Ticket

| File | Role |
|------|------|
| `baml/main.baml` | Add new BAML function definitions + output types |
| `lib/haul/ai/sandbox.ex` | Add sandbox responses for new functions |
| `lib/haul/ai.ex` | No changes needed (generic adapter) |
| `lib/haul/content/service.ex` | Schema reference for Service output |
| `lib/haul/content/site_config.ex` | Schema reference for meta_description |
| NEW `lib/haul/ai/content_generator.ex` | Elixir wrapper module |
| NEW `test/haul/ai/content_generator_test.exs` | Tests |

## Open Questions

- **"Why hire us" storage:** The ticket says "6 bullet points matching the landing page format." The landing page currently renders differentiators from OperatorProfile. The generated bullets could replace/augment those differentiators, but there's no dedicated Ash resource. Return as `[String.t()]` and let the provisioning pipeline (T-020-02) handle storage.
- **Tagline options format:** Ticket says "3 tagline options (short, punchy, professional)." Return as `[String.t()]` list; the UI (T-020-03) will let the operator pick one.
