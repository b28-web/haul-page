# haul-page — system internals
#
# Implementation details for the top-level justfile.
# Operators use `just dev`, not `just _dev`.

# ---------- dev ----------

[private]
_dev:
    #!/usr/bin/env bash
    set -euo pipefail

    # Ensure deps are current
    if [ ! -d deps ] || [ mix.exs -nt deps/.fetched ]; then
        echo ":: fetching deps"
        mix deps.get
        touch deps/.fetched
    fi

    # Ensure DB exists and is migrated
    mix ecto.create 2>/dev/null || true
    mix ecto.migrate

    echo ":: starting phoenix"
    mix phx.server

# ---------- deploy ----------

[private]
_deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    # Preflight
    if ! command -v flyctl &>/dev/null; then
        echo "error: flyctl not installed — brew install flyctl"
        exit 1
    fi

    if ! flyctl status &>/dev/null; then
        echo "error: not authenticated or app not configured — run 'flyctl auth login'"
        exit 1
    fi

    echo ":: deploying to fly.io"
    flyctl deploy --remote-only

# ---------- llm ----------

[private]
_llm:
    #!/usr/bin/env bash
    set -euo pipefail

    cat <<'CONTEXT'
    # haul-page

    ## What is this?
    A website + booking system for a junk removal / hauling / handyman operator.
    The landing page doubles as a printable poster (tear-off tabs, low-ink print
    stylesheet). Built with Phoenix + Ash Framework + LiveView. Deploys to Fly.io
    with Neon Postgres. Designed to cost < $15/month per operator.

    ## Stack
    - Elixir 1.19 / Phoenix / Ash Framework / LiveView
    - Tailwind CSS (Oswald display font + Source Sans 3 body — Google Fonts)
    - MDEx (Rust-backed markdown → HTML/HEEx, with Phoenix component injection)
    - Postgres (Neon, serverless, schema-per-tenant)
    - Fly.io (scale-to-zero, single region per operator)

    ## Status board
    docs/active/OVERVIEW.md — READ FIRST, UPDATE ALWAYS.
    Central info board: active tickets, blockers, decisions, cross-ticket notes.
    Update it when you complete work, hit a blocker, or learn something others need.

    ## Key docs
    - docs/knowledge/specification.md    — product spec, monorepo layout, deploy
    - docs/knowledge/content-system.md   — content domain design (Astro-equivalent)
    - docs/knowledge/mockup-reference.md — design tokens, typography, section layout
    - CLAUDE.md                          — agent instructions + conventions
    - CONTRIBUTING.md                    — setup, workflow, code conventions
    - DEPLOYMENT.md                      — Fly.io + Neon deploy, local release

    ## Architecture
    Single Phoenix app. Not an umbrella. Five Ash domains:
    - Accounts  — Company (tenant root), User. AshAuthentication. Schema-per-tenant.
    - Operations — Job (AshStateMachine), Quote, QuoteLineItem, Truck.
    - Disposal   — DisposalFacility, DisposalRun. Domain-specific margin tracking.
    - Billing    — Invoice, Payment, Ledger (AshDoubleEntry).
    - Content    — SiteConfig, Service, GalleryItem, Endorsement, Page (markdown).

    Multi-tenancy: AshPostgres :context strategy. Each Company gets a Postgres
    schema. Tenant set at the plug level from authenticated user's company_id.
    Cross-tenant access is architecturally impossible (schema isolation).

    ## Public pages
    - /      — landing page (server-rendered HEEx, no JS required, printable poster)
    - /scan  — QR code landing (LiveView — schedule CTA + before/after gallery)
    - /book  — booking form (LiveView — creates Job in :lead state)
    - /app   — operator dashboard (later, behind auth)

    ## Content system
    Content is Ash resources, not a separate CMS. Markdown via MDEx.
    - Seed from files: priv/content/*.yml, priv/content/pages/*.md
    - Seed task: mix haul.seed_content (idempotent)
    - Runtime: operator edits via admin UI at /app/content (later)
    - Rendering: markdown → HTML cached at write-time (body_html column)
    - Component injection: MDEx.to_heex/2 for embedding Phoenix components in markdown

    ## Task management
    - Tickets: docs/active/tickets/ (YAML frontmatter, lisa DAG)
    - Epics: docs/active/epics/ (ongoing health goals, not task-bound)
    - Stories: docs/active/stories/ (feature groupings)
    - `lisa status` — see DAG, waves, what's ready
    - `lisa validate` — check for cycles or missing deps
    - Max 2 concurrent tickets. RDSPI workflow (6 phases per ticket).

    ## Conventions
    - Ash resources are source of truth — business logic in resources, not controllers
    - Named actions: :create_from_online_booking, :complete_job (not :create, :update)
    - Multi-tenancy first: Company/User set up before any domain resources
    - Security tests in main suite: tenant isolation, policy enforcement, auth boundaries
    - No separate frontend build — Tailwind + esbuild via Mix tasks, no node_modules
    - Dark theme (pure grayscale, hue 0, saturation 0%). --radius: 0rem (sharp edges)
    - Print: @media print flips to white bg, Oswald 42pt/22pt, tear-off strip at bottom
    - Operator config via runtime env vars (OPERATOR_NAME, OPERATOR_PHONE, etc.)

    ## CI guardrails
    - Pre-commit hook: blocks debug statements, hardcoded secrets, .env files
    - CI: test (Postgres 16), quality (format + credo), guardrails (diff size < 800
      lines, no fixup/wip commits, no debug leftovers, test files for new modules)
    - PR template: security checklist (tenant isolation, policies)

    ## Maintenance obligations
    If your work changes architecture, routes, domains, or conventions, update:
    - `just llm` (.just/system.just _llm recipe) — this briefing, kept terse
    - `justfile` — top-level commands, kept to 5-7 entries max
    - `README.md` — kept under 40 lines, no prose, just facts
    These are operator/agent interfaces. Brevity is the feature.

    ## Knowledge map (dig deeper when your ticket touches these areas)
    - Multi-tenancy     → docs/knowledge/specification.md § "Domain Model" + § "Multi-Tenant Isolation"
    - Job state machine → docs/knowledge/specification.md § "Job (central resource — AshStateMachine)"
    - Content system    → docs/knowledge/content-system.md (full design: collections, MDEx, seed workflow, admin UI)
    - Design tokens     → docs/knowledge/mockup-reference.md (colors, fonts, section layout, print CSS)
    - Disposal/margin   → docs/knowledge/specification.md § "Domain: Disposal" (the key differentiator)
    - Billing/ledger    → docs/knowledge/specification.md § "Domain: Billing" (AshDoubleEntry)
    - Background jobs   → docs/knowledge/specification.md § "Background Jobs (AshOban)" (triggers table)
    - Auth/roles        → docs/knowledge/specification.md § "Authorization Model" (role hierarchy, policies)
    - Deploy/infra      → DEPLOYMENT.md (Fly.io, Neon, Docker, local release, costs)
    - CI/guardrails     → .github/workflows/ci.yml + .githooks/pre-commit
    - RDSPI workflow    → docs/knowledge/rdspi-workflow.md (6 phases, artifact format)
    - Epics (health)    → docs/active/epics/ (8 epics: dev env, deploy, surface, domain, content, first customer, demo, security)
    CONTEXT

# ---------- setup ----------

[private]
_setup:
    #!/usr/bin/env bash
    set -euo pipefail

    echo ":: checking prerequisites"
    command -v elixir &>/dev/null || { echo "error: elixir not found — run 'mise install'"; exit 1; }
    command -v psql &>/dev/null   || { echo "error: psql not found — brew install libpq"; exit 1; }

    echo ":: installing mix deps"
    mix local.hex --force --if-missing
    mix local.rebar --force --if-missing
    mix deps.get

    echo ":: compiling"
    mix compile

    echo ":: setting up database"
    mix ecto.setup

    echo ":: building assets"
    mix assets.setup

    echo ":: done — run 'just dev' to start"

# ---------- test ----------

[private]
_test *args='':
    mix test {{ args }}

# ---------- quality ----------

[private]
_quality:
    #!/usr/bin/env bash
    set -euo pipefail

    echo ":: format"
    mix format --check-formatted

    echo ":: credo"
    mix credo --strict

    echo ":: dialyzer"
    mix dialyzer

# ---------- clean ----------

[private]
_clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ":: cleaning build artifacts"
    rm -rf _build deps
    echo ":: done"
