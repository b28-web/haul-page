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
    A single-page website + booking form for a junk removal / hauling / handyman
    operator. Built with Phoenix + Ash Framework + LiveView. Deploys to Fly.io
    with Neon Postgres. Designed to cost < $15/month.

    ## Stack
    - Elixir / Phoenix / Ash Framework / LiveView
    - Tailwind CSS (Oswald + Source Sans 3 typography)
    - Postgres (Neon, serverless)
    - Fly.io (scale-to-zero)

    ## Key files
    - docs/knowledge/specification.md    — full product spec
    - docs/knowledge/mockup-reference.md — design tokens + layout reference
    - docs/active/epics/                 — ongoing health goals
    - docs/active/stories/               — feature stories
    - docs/active/tickets/               — implementation tickets (lisa DAG)
    - CLAUDE.md                          — agent instructions

    ## Architecture
    Single Phoenix app. Not an umbrella. Four Ash domains:
    - Accounts (Company, User — multi-tenant)
    - Operations (Job, Quote, Truck — state machine)
    - Disposal (Facilities, Runs — domain-specific)
    - Billing (Invoice, Payment, Ledger — AshDoubleEntry)

    ## Public pages
    - /      — landing page (server-rendered HEEx, printable poster)
    - /scan  — QR code landing (LiveView, before/after gallery, endorsements)
    - /book  — booking form (LiveView, creates Job in :lead state)

    ## Task management
    Tickets are in docs/active/tickets/ with YAML frontmatter.
    Use `lisa status` to see the DAG and what's ready.
    Use `lisa validate` to check for cycles or missing deps.
    Max 2 concurrent tickets via lisa's agent swarm.

    ## Conventions
    - Ash resources are the source of truth for business logic
    - All actions are named and intent-driven (e.g., :create_from_online_booking)
    - Dark theme is default (grayscale palette, no warm tones)
    - Print stylesheet strips backgrounds, uses Oswald 42pt/22pt headings
    - Operator config via runtime env vars, not code changes
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
