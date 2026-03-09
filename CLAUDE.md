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

- `docs/knowledge/specification.md` — Full product spec, monorepo structure, deploy strategy
- `docs/knowledge/content-system.md` — Content domain design (Astro-equivalent on Ash)
- `docs/knowledge/mockup-reference.md` — Design tokens, typography, layout from prototype

---

## Agent Context: `just llm`

Run `just llm` to get a concise briefing on the repo — stack, architecture, key files, conventions, and task management. **This is the inter-agent handoff mechanism.** When a new agent session starts (lisa ticket, manual claude invocation, or any LLM coder), `just llm` is the first thing to read.

**Keep `just llm` accurate.** If you change the architecture, add a new public route, shift conventions, or introduce a new domain, update the `_llm` recipe in `.just/system.just` to reflect it. The output should be a self-contained briefing that lets a fresh agent work productively without reading every file in the repo. Think of it as a living `README` optimized for LLM context windows — terse, structured, no prose.

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
