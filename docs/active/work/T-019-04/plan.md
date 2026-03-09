# T-019-04 Plan: Onboarding Agent Prompt

## Step 1: Create prompt directory and system prompt file
- Create `priv/prompts/` directory
- Write `priv/prompts/onboarding_agent.md` with:
  - YAML frontmatter: `version: v1`
  - Role and introduction section
  - Conversation flow (anchoring on business name, then contact, services, differentiators)
  - Field requirements table (required vs optional)
  - Edge case handling (terse, chatty, off-topic, pricing questions, non-English)
  - Completion detection rules
  - Tone guidelines
- Verify: file exists, frontmatter parseable

## Step 2: Write prompt loader module
- Create `lib/haul/ai/prompt.ex`
- `load/1` — reads file, strips YAML frontmatter, returns content
- `version/1` — parses frontmatter, returns version string
- Uses `Application.app_dir` for release compatibility with fallback to `priv/` for dev
- Verify: module compiles

## Step 3: Write prompt loader tests
- Create `test/haul/ai/prompt_test.exs`
- Test `load/1` returns content without frontmatter
- Test `version/1` returns "v1"
- Test error handling for missing files
- Verify: tests pass

## Step 4: Write onboarding prompt content tests
- Create `test/haul/ai/onboarding_prompt_test.exs`
- Test prompt contains required field names
- Test prompt contains service category examples
- Test prompt contains persona/tone instructions
- Test prompt contains edge case handling
- Verify: tests pass

## Step 5: Document persona test scenarios
- Add persona scenarios to work artifact (not automated tests)
- 5 personas: terse, chatty, unsure, pricing-curious, non-English-dominant
- Each with expected agent behavior and conversation flow
- This documents the design intent for future integration testing

## Testing strategy
- **Unit tests**: Prompt loader (`load/1`, `version/1`, error handling)
- **Content tests**: Prompt file contains required sections and field names
- **Manual/future**: Persona conversation scenarios documented for integration testing in T-019-01/02
- All tests run with `mix test test/haul/ai/prompt_test.exs test/haul/ai/onboarding_prompt_test.exs`
