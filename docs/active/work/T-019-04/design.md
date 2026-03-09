# T-019-04 Design: Onboarding Agent Prompt

## Decision: Prompt architecture

### Option A: Single monolithic system prompt
One markdown file with all instructions, persona, field requirements, and conversation flow.
- Pros: Simple to load, easy to version, one file to review
- Cons: Large prompt, harder to A/B test specific sections

### Option B: Modular prompt with sections loaded separately
Separate files for persona, field requirements, conversation flow, edge cases.
- Pros: Can swap sections independently, easier to A/B test
- Cons: Over-engineered for v1, adds loader complexity

### Option C: Single prompt file with version header
One file with structured sections and a version tag at the top. Future versions can be separate files (v2, v3).
- Pros: Simple like A, but with versioning built in. Can split later if needed.
- Cons: None significant for v1.

**Decision: Option C.** One prompt file with version header. Versioning is a frontmatter concern. Splitting can happen later when there's actual A/B testing infrastructure.

## Decision: Conversation flow strategy

### Approach: Adaptive collection with anchoring
1. **Anchor on business name** — first question, establishes context
2. **Batch related questions** — don't ask one field at a time (feels like a form)
3. **Adaptive probing** — if they give a lot upfront, skip covered questions
4. **Natural transitions** — "Great name! And how should customers reach you?" not "Please provide phone number."
5. **Completion detection** — when required fields are covered, transition to confirmation

This matches how a human onboarding specialist would work: get the big picture, then fill gaps.

## Decision: Prompt tone

**Warm but efficient.** Haulers are busy people. The agent should:
- Use casual-professional language (not corporate, not overly casual)
- Keep responses to 2-3 sentences max
- Never repeat information back unnecessarily
- Skip pleasantries after the first exchange
- Use concrete examples when probing ("Like junk removal, yard waste, cleanouts?")

## Decision: Field collection strategy

The prompt must guide collection of fields that map to OperatorProfile:

| Priority | Field | Collection strategy |
|----------|-------|-------------------|
| 1 | business_name | Ask first, explicitly |
| 2 | phone, email | Ask together as "contact info" |
| 3 | owner_name | "And who should we say runs the show?" |
| 4 | services | Probe with examples from ServiceCategory |
| 5 | service_area | "Where do you serve?" |
| 6 | differentiators | "What makes your business stand out?" |
| 7 | tagline | Offer to generate one based on differentiators |
| 8 | years_in_business | Weave into differentiators probe |

## Decision: Edge case handling

| Scenario | Strategy |
|----------|----------|
| One-word answers | Ask follow-up with examples |
| Info dump (everything at once) | Acknowledge all, ask only for missing fields |
| Off-topic | "Good question! Let me help you get your site set up first, then we can chat about that." |
| Pricing questions | "We'll cover plans and pricing once your site is ready. Right now let's get your business info set." |
| Non-English speaker | Use simple language, short sentences, avoid idioms |
| Unsure about services | Offer the common categories as a checklist |
| Wants to skip fields | Allow skipping optional fields, insist on required ones gently |

## Decision: Testing approach

The ticket requires testing against 5+ personas. Since this is a prompt design ticket (not a code integration ticket), testing means:

1. **Write the prompt**
2. **Create test conversation scripts** — structured scenarios with expected behaviors
3. **Write ExUnit tests** — use the sandbox adapter to verify prompt loading and version tracking
4. **Document persona scenarios** — in the work artifact, not as automated tests (can't automate LLM conversation quality in unit tests)

The actual conversation quality testing happens when T-019-01 (chat LiveView) and T-019-02 (live extraction) integrate the prompt. For this ticket, we verify:
- Prompt loads from file correctly
- Version is parseable
- Prompt contains required instruction sections
- Prompt module API works

## Decision: Prompt loader module

New module `Haul.AI.Prompt` with:
- `load(name)` — reads from `priv/prompts/{name}.md`, caches in ETS or module attribute
- `version(name)` — extracts version from frontmatter
- Runtime loading (not compiled in) per acceptance criteria

Keep it simple — `File.read!` with `Application.app_dir` for release compatibility.

## Rejected alternatives

- **Database-stored prompts**: Over-engineered. No admin UI for prompt editing yet. File-based is correct for v1.
- **Template variables in prompt**: Unnecessary. The prompt is static instructions to Claude, not a template filled with user data.
- **Multiple prompt files per version**: Premature. Version in frontmatter is sufficient until A/B testing exists.
