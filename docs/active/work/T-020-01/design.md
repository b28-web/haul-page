# T-020-01 Design: Content Generation Functions

## Decision: BAML Architecture

### Option A: Single BAML function, one big prompt
One `GenerateAllContent` function that takes the full profile and returns all content at once.
- Pro: Single LLM call, cheaper
- Con: Complex output type, harder to retry partial failures, one bad field means re-running everything
- **Rejected:** Too fragile, harder to test individual outputs

### Option B: Four separate BAML functions (chosen)
Individual functions matching the ticket AC: `GenerateServiceDescriptions`, `GenerateTagline`, `GenerateWhyHireUs`, `GenerateMetaDescription`.
- Pro: Each function has clean typed output, can be retried independently, easy to test
- Con: 4 LLM calls per generation pass (but Haiku is cheap)
- **Chosen:** Matches ticket AC exactly, clean separation of concerns

### Option C: Two BAML functions (batch short + batch long)
Group short-text outputs together, long-text outputs together.
- **Rejected:** Arbitrary grouping, no clear benefit over Option B

## Decision: BAML Client for Haiku

Add a second BAML client `AnthropicHaiku` in `main.baml` using `claude-haiku-4-5-20251001`. Generation functions reference this client while extraction continues using Sonnet.

## Decision: Output Types

### GenerateServiceDescriptions
- Input: service names + business context (business_name, service_area, differentiators)
- Output: `ServiceDescription[]` — each has `service_name: string`, `description: string`
- Maps 1:1 to Service.description field
- 2-3 sentences per description as specified in AC

### GenerateTagline
- Input: business info (business_name, service_area, services, differentiators)
- Output: `TaglineOptions` — `options: string[]` (3 items)
- Short, punchy, professional as specified
- Caller picks one to store in SiteConfig.tagline

### GenerateWhyHireUs
- Input: differentiators + business context
- Output: `WhyHireUsBullets` — `bullets: string[]` (6 items)
- Matches landing page format (bullet points)
- Can be stored as differentiators on the profile or rendered directly

### GenerateMetaDescription
- Input: business info summary
- Output: `MetaDescriptionResult` — `description: string`
- Prompt enforces ≤160 chars
- Maps to SiteConfig.meta_description

## Decision: Elixir Wrapper (`Haul.AI.ContentGenerator`)

Follow the `Haul.AI.Extractor` pattern:
- Module calls `Haul.AI.call_function/2` for each generation function
- Returns typed Elixir structs/maps
- Includes retry logic for transient errors (reuse pattern from Extractor)
- Logs token usage via `Logger.info` with structured metadata

Public API:
```elixir
ContentGenerator.generate_service_descriptions(profile) :: {:ok, [%{service_name: String.t(), description: String.t()}]} | {:error, term()}
ContentGenerator.generate_taglines(profile) :: {:ok, [String.t()]} | {:error, term()}
ContentGenerator.generate_why_hire_us(profile) :: {:ok, [String.t()]} | {:error, term()}
ContentGenerator.generate_meta_description(profile) :: {:ok, String.t()} | {:error, term()}
ContentGenerator.generate_all(profile) :: {:ok, map()} | {:error, term()}
```

`generate_all/1` calls all four in sequence and returns a consolidated result map. This is the main entry point for the provisioning pipeline (T-020-02).

## Decision: Sandbox Responses

Add default responses for all four functions in `Haul.AI.Sandbox`:
- `GenerateServiceDescriptions` — returns descriptions matching the sandbox profile's 3 services
- `GenerateTagline` — returns 3 sample taglines
- `GenerateWhyHireUs` — returns 6 sample bullet points
- `GenerateMetaDescription` — returns a sample ≤160 char description

## Decision: Validation

Generated content is validated before returning:
- Service descriptions: non-empty string for each service
- Taglines: exactly 3 options, all non-empty
- Why hire us: exactly 6 bullets, all non-empty
- Meta description: non-empty, ≤160 chars (trim if LLM exceeds)

Validation failures log warnings but don't fail the call — we trust the LLM output is usually correct and the Ash resource validations are the final gate.

## Decision: Token Logging

Log via `Logger.info` after each successful call:
```
[ContentGenerator] GenerateServiceDescriptions completed (profile: "Business Name")
```

BAML doesn't expose token counts through the current NIF interface. We log the function name and profile identifier. Detailed token tracking can be added when the BAML NIF supports usage metadata.

## What Was Rejected

- **Streaming for generation:** Unnecessary — these are short outputs, not chat
- **Caching generated content:** Premature — generation happens once during onboarding
- **Custom Ash resource for generated content:** Over-engineering — generated text maps directly to existing resources via ProfileMapper pattern
- **Async/parallel generation:** Could parallelize the 4 calls with Task.async, but sequential is simpler and Haiku is fast. Can optimize later if needed.
