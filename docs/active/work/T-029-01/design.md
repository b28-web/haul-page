# T-029-01 Design — Document Test Tiers

## Decision: Documentation Structure

### Option A: Single comprehensive doc + inline updates

Create `docs/knowledge/test-architecture.md` as the canonical reference. Add brief tier definitions and a link to it in CLAUDE.md, `just llm`, and RDSPI workflow. The comprehensive doc does the heavy lifting; other files just reference it.

### Option B: Distribute content across existing docs

Put tier definitions in CLAUDE.md, examples in a separate guide, factory patterns in a third file. More granular but harder to maintain and discover.

### Option C: Inline everything in CLAUDE.md

Put all test tier documentation directly in CLAUDE.md. Simplest to find but bloats the agent instruction file.

**Chosen: Option A.** Single source of truth in `test-architecture.md`, brief references elsewhere. Matches the existing pattern (content-system.md, mockup-reference.md are standalone knowledge docs linked from CLAUDE.md).

## Content Design

### test-architecture.md sections

1. **3-Tier Model** — table with tier name, test case, DB, HTTP, async, speed
2. **Decision Tree** — simple flowchart: "Does it need DB? No → Tier 1. Does it need HTTP? No → Tier 2. Yes → Tier 3."
3. **Tier 1 Examples** — formatting_test.exs, billing_test.exs patterns
4. **Tier 2 Examples** — service_test.exs, user_test.exs patterns
5. **Tier 3 Examples** — page_controller_test.exs, billing_live_test.exs patterns
6. **Factory Usage** — when to use which factory, authorize?: false convention
7. **setup_all vs setup** — guidance on shared vs per-test setup
8. **When async: true is safe** — only when no DB/GenServer/ETS state
9. **Anti-patterns** — signs your test is at the wrong tier

### CLAUDE.md additions

Add to "Test Targeting" section:
- 3 one-line tier definitions
- Rule: "Default to lowest viable tier. Unit > Resource > Integration."
- Link to test-architecture.md

### just llm addition

Add 3-line test tier summary to Conventions section.

### RDSPI addition

Add to review phase checklist: "Are new tests at the lowest viable tier?"

## Rejected Alternatives

- **Option B rejected:** Fragmenting test docs across multiple files creates maintenance burden and discovery friction.
- **Option C rejected:** CLAUDE.md is already dense. Full test architecture docs would add 150+ lines to a file agents load on every session.
- **Generating test tier annotations in code:** Considered adding `@moduletag :tier_1` to test files. Rejected — this is a documentation ticket, and the convention should be established in docs first. Code annotations could be a follow-up.

## Tone & Style

- Terse, scannable tables over prose
- Concrete file paths over abstract descriptions
- Decision tree as simple text, not a diagram
- Anti-patterns as "if you see X, do Y instead" format
