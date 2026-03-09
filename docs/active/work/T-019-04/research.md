# T-019-04 Research: Onboarding Agent Prompt

## What exists

### BAML types (baml/main.baml)
- `OperatorProfile` struct: business_name, owner_name, phone, email, service_area, tagline?, years_in_business?, services[], differentiators[]
- `ServiceOffering`: name, description?, category (ServiceCategory enum)
- `ServiceCategory` enum: JUNK_REMOVAL, CLEANOUTS, YARD_WASTE, REPAIRS, ASSEMBLY, MOVING_HELP, OTHER
- Client: Anthropic with `claude-sonnet-4-20250514`

### Elixir profile types (lib/haul/ai/)
- `OperatorProfile` struct mirrors BAML types with `from_baml/1` parser
- `ProfileMapper` — pure data transforms:
  - `to_company_attrs/1`, `to_site_config_attrs/1`, `to_service_attrs_list/1`
  - `missing_fields/1` — returns required fields that are nil
  - Required fields: `[:business_name, :phone, :email]`
- Sandbox adapter returns fixture OperatorProfile for `ExtractOperatorProfile` calls

### Content domain resources
- **SiteConfig**: business_name (req), phone (req), email, tagline, service_area, address, coupon_text, meta_description, primary_color, logo_url, owner_name
- **Service**: title (req), description (req), icon (req), sort_order, active, category (atom enum)
- **Endorsement**: customer_name, quote_text, star_rating, source, date, featured, active, sort_order
- **GalleryItem**: before/after image URLs, caption, alt_text, sort_order, featured, active

### Onboarding flow (lib/haul/onboarding.ex)
- `run/1` — creates Company → provisions tenant → seeds content → creates owner user
- `signup/1` — same but with password for self-service
- Takes: name, phone, email, area
- OnboardingLive: 6-step wizard (confirm info, site address, services, logo upload, preview, go live)

### Default content (priv/content/defaults/)
- site_config.yml template with placeholder values
- 6 service YAML files (junk-removal, cleanouts, yard-waste, repairs, assembly, moving-help)
- 3 sample endorsements, 4 sample gallery items

### AI adapter pattern (lib/haul/ai.ex)
- Callback-based: `call_function(function_name, args)` delegates to adapter
- Sandbox adapter returns fixture data for dev/test
- BAML adapter uses `baml_elixir` NIF for production calls

### No existing prompts
- `priv/prompts/` directory does not exist yet
- No system prompt files anywhere in the codebase
- The `ExtractOperatorProfile` BAML function is not yet defined (that's T-018-03)

## Data the prompt must collect

### Required (from ProfileMapper.missing_fields/1)
| Field | Source | Notes |
|-------|--------|-------|
| business_name | Ask first | Anchors conversation, derives URL slug |
| phone | Ask | Primary contact, shown on site |
| email | Ask | For notifications and account |

### Important (mapped to SiteConfig/Services)
| Field | Source | Notes |
|-------|--------|-------|
| owner_name | Ask | Personal touch on site |
| service_area | Ask | Geographic coverage for SEO |
| services | Ask/probe | Maps to Service resources with categories |
| tagline | Derive or ask | Can be generated from differentiators |

### Nice to have (enrich profile)
| Field | Source | Notes |
|-------|--------|-------|
| years_in_business | Probe | Trust signal |
| differentiators | Probe | "What makes you different?" |

## Conversation design constraints

1. **Target audience**: Junk removal operators. Busy, practical, often on the road. Not tech-savvy.
2. **Conversation length**: 5-10 messages ideal. Must not feel like a form.
3. **Extraction happens downstream**: T-018-03 defines `ExtractOperatorProfile` — the prompt guides conversation, extraction is separate.
4. **The prompt guides Claude, not BAML**: This is a system prompt for a chat agent, not a BAML function prompt.
5. **Runtime loading**: Prompt loaded from file at runtime, not compiled in. Enables versioning and hot updates.
6. **Required personas for testing**: terse owner, chatty owner, unsure owner, pricing-curious owner, non-English-dominant speaker.

## Key patterns in hauler businesses
- Multi-service: most do junk removal + 1-3 other things (cleanouts, yard waste, light repairs)
- Franchise vs independent: affects naming, service area, branding
- Seasonal services: yard waste peaks spring/fall, cleanouts year-round
- Common names: "[Name]'s Hauling", "[City] Junk Removal", "1-800-GOT-JUNK" style
- Service areas: typically metro-area or county-based, not nationwide

## File placement
- System prompt: `priv/prompts/onboarding_agent.md`
- Tests: `test/haul/ai/onboarding_prompt_test.exs`
- Prompt loader: extend `lib/haul/ai.ex` or new module
