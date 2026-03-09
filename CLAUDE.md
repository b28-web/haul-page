# CLAUDE.md

## Project

haul-page — A website + booking system for junk removal operators. Phoenix + Ash + LiveView, deployed on Fly.io.

### Directory Conventions

```
docs/active/tickets/    # Ticket files (markdown with YAML frontmatter)
docs/active/stories/    # Story files (same frontmatter pattern)
docs/active/epics/      # Ongoing health goals (not task-bound)
docs/active/work/       # Work artifacts, one subdirectory per ticket ID
docs/knowledge/         # Specs, design decisions, reference docs
.just/                  # System-level justfile (private recipes)
.githooks/              # Pre-commit hooks (auto-configured via core.hooksPath)
```

### Key Docs

- `docs/active/OVERVIEW.md` — **Status board. Read first, update always.** Central information board for all agents.
- `docs/knowledge/specification.md` — Full product spec, monorepo structure, deploy strategy
- `docs/knowledge/content-system.md` — Content domain design (Astro-equivalent on Ash)
- `docs/knowledge/mockup-reference.md` — Design tokens, typography, layout from prototype

---

## Agent Communication

### `docs/active/OVERVIEW.md` — Status board

**Read this at the start of every session. Update it when you finish work.** This is how agents communicate with the developer and with each other. It tracks:

- What's in progress and who's working on what
- Recently completed tickets
- Blockers and risks
- Decisions made during implementation that aren't in the spec
- Cross-ticket notes (things you learned that another agent needs to know)

If you complete a ticket, move it from "Active" to "Recently completed." If you hit a blocker, log it. If you make a decision that affects other tickets, write it down. The developer checks this file to understand project state without reading every ticket.

### `just llm` — Agent onboarding

Run `just llm` for a concise repo briefing — stack, architecture, key files, conventions. **This is the inter-agent handoff mechanism.** When a new agent session starts (lisa ticket, manual claude invocation, or any LLM coder), `just llm` is the first thing to read.

**Keep `just llm` accurate.** If you change the architecture, add a new public route, shift conventions, or introduce a new domain, update the `_llm` recipe in `.just/system.just` to reflect it. Terse, structured, no prose.

---

## Workflow

The RDSPI workflow definition is in `docs/knowledge/rdspi-workflow.md` and is injected into agent context by lisa automatically.

Use `lisa status` to see the ticket DAG. Use `lisa validate` to check for cycles or missing deps. Max 2 concurrent tickets.

## Code Conventions

- Ash resources are the source of truth for business logic
- All Ash actions are named and intent-driven (`:create_from_online_booking`, not `:create`)
- Multi-tenancy via AshPostgres `:context` strategy (schema-per-tenant) — set up before domain resources
- Security tests (tenant isolation, policy enforcement) are part of `mix test`, not separate
- No separate frontend framework — Tailwind + esbuild via Mix tasks, no node_modules
- Dark theme default (pure grayscale). Oswald for headings, Source Sans 3 for body
- Operator config via runtime env vars, not code changes
