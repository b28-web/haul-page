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

### Lisa — DAG-driven agent scheduler

Lisa is a Rust CLI + Zellij WASM plugin that manages Claude Code agent sessions. It reads the ticket DAG from `docs/active/tickets/`, computes dependency waves, and spawns/tracks Claude Code sessions in Zellij terminal panes — one agent per ticket, max 2 concurrent.

**Commands:**
- `lisa status` — print the ticket DAG: waves, dependencies, what's ready/blocked/done
- `lisa validate` — check for cycles, missing deps, or structural errors
- `lisa loop` (or `just work`) — launch the Zellij session with agent panes. Lisa assigns ready tickets to agents, monitors phase transitions, and serializes git commits across agents.

**How it works:**
1. Lisa reads ticket frontmatter (`id`, `status`, `phase`, `depends_on`) and builds a DAG
2. `lisa loop` generates a Zellij layout with 2× max_threads panes + a dashboard plugin
3. When a pane is idle, Lisa picks the next ready ticket and runs `claude --dangerously-skip-permissions` with the ticket prompt
4. Each agent follows the RDSPI workflow (Research → Design → Structure → Plan → Implement → Review)
5. Agents inherit project config: CLAUDE.md, `.mcp.json` (Playwright MCP), and all repo context

**Config:** `.lisa.toml` at project root — ticket/story/work dirs, max threads (2), scheduling options.

The RDSPI workflow definition is in `docs/knowledge/rdspi-workflow.md` and is injected into agent context by lisa automatically.

### Planning and status commands

| Command | Purpose |
|---|---|
| `just status` | Raw DAG dump (`lisa status`) |
| `just overview` | Spawns a Claude agent to survey the repo and update OVERVIEW.md |
| `just status-agent` | Deep survey + interactive planning session — create tickets/stories/epics |
| `just work` | Launch `lisa loop` — agents implement the tickets |

The core loop: `just status-agent` (plan) → `just work` (execute) → `just overview` (review).

## Code Conventions

- Ash resources are the source of truth for business logic
- All Ash actions are named and intent-driven (`:create_from_online_booking`, not `:create`)
- Multi-tenancy via AshPostgres `:context` strategy (schema-per-tenant) — set up before domain resources
- Security tests (tenant isolation, policy enforcement) are part of `mix test`, not separate
- No separate frontend framework — Tailwind + esbuild via Mix tasks, no node_modules
- Dark theme default (pure grayscale). Oswald for headings, Source Sans 3 for body
- Operator config via runtime env vars, not code changes

## Test Targeting

Run **targeted tests** during implementation, **full suite** before review.

### Quick reference

```bash
# Single file
mix test test/haul/billing_test.exs

# Directory (all files under it)
mix test test/haul/accounts/

# Multiple paths
mix test test/haul/content/ test/haul_web/controllers/page_controller_test.exs

# Single test by line number
mix test test/haul/billing_test.exs:42

# Full suite (before review)
mix test
```

### Source → test mapping

| Domain | Source (`lib/`) | Tests (`test/`) | Also run when changed |
|--------|----------------|-----------------|----------------------|
| Accounts | `haul/accounts/` | `haul/accounts/` | `haul/tenant_isolation_test.exs` |
| AI | `haul/ai/` | `haul/ai/` | — |
| Billing | `haul/billing/` | `haul/billing_test.exs` | `haul_web/live/app/billing_live_test.exs`, `haul_web/live/app/billing_qa_test.exs` |
| Content | `haul/content/` | `haul/content/` | `haul_web/controllers/page_controller_test.exs` |
| Domains | `haul/domains/` | `haul/domains_test.exs` | `haul_web/plugs/tenant_resolver_test.exs` |
| Notifications | `haul/notifications/` | `haul/notifications/` | `haul/workers/send_booking_email_test.exs`, `haul/workers/send_booking_sms_test.exs` |
| Onboarding | `haul/onboarding.ex` | `haul/onboarding_test.exs` | `haul_web/live/app/onboarding_live_test.exs` |
| Operations | `haul/operations/` | `haul/operations/` | — |
| Payments | `haul/payments/` | `haul/payments_test.exs` | `haul_web/live/payment_live_test.exs` |
| Places | `haul/places/` | `haul/places/` | `haul_web/controllers/places_controller_test.exs` |
| Storage | `haul/storage/` | `haul/storage_test.exs` | — |
| Workers | `haul/workers/` | `haul/workers/` | — |
| Controllers | `haul_web/controllers/` | `haul_web/controllers/` | — |
| LiveViews | `haul_web/live/` | `haul_web/live/` | — |
| LiveViews (app) | `haul_web/live/app/` | `haul_web/live/app/` | — |
| Plugs | `haul_web/plugs/` | `haul_web/plugs/` | — |
| Mix tasks | `mix/tasks/haul/` | `mix/tasks/haul/` | — |

### Cross-cutting tests

Run these when your change touches shared infrastructure:

| Test file | Run when you change... |
|-----------|----------------------|
| `test/haul/tenant_isolation_test.exs` | Tenant resolution, policies, any Ash resource |
| `test/haul_web/smoke_test.exs` | Routes, plugs, endpoint config |
| `test/haul/rate_limiter_test.exs` | Rate limiting, plug pipeline |
| `test/haul_web/live/tenant_hook_test.exs` | LiveView session, tenant propagation |

### Rules

1. **During implement:** run targeted tests after each meaningful change
2. **Before review:** run `mix test` (full suite) and note the result in review.md
3. Targeted runs for a typical ticket scope should complete in **under 15 seconds**
