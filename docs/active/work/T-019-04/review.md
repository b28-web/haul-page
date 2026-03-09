# T-019-04 Review: Onboarding Agent Prompt

## Summary

Designed and implemented the system prompt for the conversational onboarding AI agent, plus a runtime prompt loader module. The prompt guides a Claude-powered agent through collecting business information from junk removal operators in a natural, efficient conversation.

## Files created

| File | Purpose |
|------|---------|
| `priv/prompts/onboarding_agent.md` | System prompt (v1) with YAML frontmatter |
| `lib/haul/ai/prompt.ex` | `Haul.AI.Prompt` — runtime prompt loader with frontmatter parsing |
| `test/haul/ai/prompt_test.exs` | Loader unit tests (4 tests) |
| `test/haul/ai/onboarding_prompt_test.exs` | Prompt content verification tests (15 tests) |
| `docs/active/work/T-019-04/` | RDSPI work artifacts (research, design, structure, plan, progress) |

## Test coverage

- **19 tests, 0 failures**
- Prompt loader: load, frontmatter stripping, version extraction, error handling
- Prompt content: required fields mentioned, service categories covered, all 5+ persona scenarios documented, conversation flow elements present, version is v1

## Acceptance criteria checklist

- [x] System prompt in `priv/prompts/onboarding_agent.md` (loaded at runtime, not compiled in)
- [x] Prompt instructs agent to introduce itself with specified opening
- [x] Asks for business name first
- [x] Naturally collects: owner name, phone, email, service area, services offered
- [x] Probes for differentiators and years in business
- [x] Handles common hauler patterns (multi-service, seasonal, franchise vs independent)
- [x] Knows when to stop (required fields collected → wrap-up transition)
- [x] Stays focused (off-topic redirection instructions)
- [x] Warm but efficient tone
- [x] 5+ persona scenarios covered: terse, chatty, unsure, pricing-curious, non-English-dominant
- [x] Version tracked (v1 in frontmatter, extractable via `Prompt.version/1`)

## Design decisions

1. **Single prompt file with version frontmatter** — simple for v1, can split into multiple files for A/B testing later.
2. **No caching in prompt loader** — file reads are cheap, and runtime reloading enables hot updates without redeployment.
3. **Frontmatter stripping** — `load/1` returns clean prompt content without YAML header. Consumers don't need to parse it.
4. **`Application.app_dir` with fallback** — works in both release mode and dev/test.

## Open concerns

1. **No live conversation testing** — the prompt is tested structurally (correct fields, sections, version) but actual conversation quality can only be verified when T-019-01 (chat LiveView) integrates it. The prompt design is based on hauler domain knowledge and conversation design best practices.
2. **Prompt length** — at ~120 lines, the system prompt is moderate. If token budget becomes a concern with long conversations, the prompt could be trimmed, but Claude handles this size without issues.
3. **No multi-language support** — the prompt instructs the agent to use simple language for non-English speakers, but the prompt itself and the agent's responses will be in English. Full i18n is out of scope.

## Dependencies satisfied

- T-018-02 (profile types) ✓ — prompt field names align with OperatorProfile struct fields
- ProfileMapper required fields (business_name, phone, email) match the prompt's required fields

## What downstream tickets need to know

- **T-019-01 (chat LiveView)**: Call `Haul.AI.Prompt.load("onboarding_agent")` to get the system prompt. Pass it as the system message when calling the Claude API.
- **T-019-02 (live extraction)**: The prompt explicitly states "Do not output structured data." Extraction happens separately via `ExtractOperatorProfile` (T-018-03) on the conversation transcript.
- **T-019-05 (fallback form)**: If the AI agent is unavailable, the fallback form should collect the same required fields: business_name, phone, email.
