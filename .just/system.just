# haul-page — system internals
#
# Implementation details for the top-level justfile.
# Operators use `just dev`, not `just _dev`.

# Ensure mise-managed tools (elixir, erlang) are on PATH for agent shells
# that don't get interactive shell activation (e.g. Claude Code Bash tool).
export PATH := env("HOME") + "/.local/share/mise/shims:" + env("PATH")

# ---------- dev ----------

[private]
_dev:
    #!/usr/bin/env bash
    set -euo pipefail

    DEV_PORT="${PORT:-4000}"
    PIDFILE=".dev.pid"

    # --- singleton guard ---
    # If a dev server is already listening on the port, don't start another.
    if lsof -iTCP:"$DEV_PORT" -sTCP:LISTEN -t &>/dev/null; then
        echo ":: dev server already running on port $DEV_PORT (pid $(lsof -iTCP:$DEV_PORT -sTCP:LISTEN -t | head -1))"
        exit 0
    fi

    # Stale pidfile from a crashed session
    if [ -f "$PIDFILE" ]; then
        OLD_PID=$(cat "$PIDFILE")
        if ! kill -0 "$OLD_PID" 2>/dev/null; then
            rm -f "$PIDFILE"
        else
            echo ":: dev server already running (pid $OLD_PID)"
            exit 0
        fi
    fi

    # --- setup ---
    # Ensure deps are current
    if [ ! -d deps ] || [ mix.exs -nt deps/.fetched ]; then
        echo ":: fetching deps"
        mix deps.get
        touch deps/.fetched
    fi

    # Ensure DB exists and is migrated
    mix ecto.create 2>/dev/null || true
    mix ecto.migrate

    # --- start ---
    LOGFILE=".dev.log"
    echo ":: starting phoenix on port $DEV_PORT (log: $LOGFILE)"
    mix phx.server > "$LOGFILE" 2>&1 &
    PHX_PID=$!
    echo "$PHX_PID" > "$PIDFILE"

    cleanup() {
        rm -f "$PIDFILE"
    }
    trap cleanup EXIT INT TERM

    # Wait briefly and verify it didn't crash on startup
    sleep 2
    if ! kill -0 "$PHX_PID" 2>/dev/null; then
        echo ":: server exited immediately — check $LOGFILE"
        cat "$LOGFILE"
        exit 1
    fi

    echo ":: dev server running (pid $PHX_PID, port $DEV_PORT)"
    wait "$PHX_PID"

[private]
_dev-status:
    #!/usr/bin/env bash
    set -euo pipefail

    DEV_PORT="${PORT:-4000}"
    PIDFILE=".dev.pid"

    # Check port
    PID=$(lsof -iTCP:"$DEV_PORT" -sTCP:LISTEN -t 2>/dev/null | head -1 || true)
    if [ -z "$PID" ]; then
        echo "status: not running"
        echo "port:   $DEV_PORT (free)"
        exit 1
    fi

    echo "status: running"
    echo "pid:    $PID"
    echo "port:   $DEV_PORT"
    echo "uptime: $(ps -o etime= -p "$PID" 2>/dev/null | xargs)"
    echo "memory: $(ps -o rss= -p "$PID" 2>/dev/null | awk '{printf "%.0f MB", $1/1024}')"

    # Health check
    if curl -sf "http://localhost:$DEV_PORT/healthz" -o /dev/null 2>/dev/null; then
        echo "health: ok"
    elif curl -sf "http://localhost:$DEV_PORT/" -o /dev/null 2>/dev/null; then
        echo "health: ok (/ responds, no /healthz yet)"
    else
        echo "health: port open but not responding to HTTP"
    fi

[private]
_dev-log *args='50':
    #!/usr/bin/env bash
    set -euo pipefail

    LOGFILE=".dev.log"
    if [ ! -f "$LOGFILE" ]; then
        echo ":: no log file — dev server hasn't been started"
        exit 1
    fi

    tail -n {{ args }} "$LOGFILE"

[private]
_dev-down:
    #!/usr/bin/env bash
    set -euo pipefail

    DEV_PORT="${PORT:-4000}"
    PIDFILE=".dev.pid"

    # Try pidfile first
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo ":: stopping dev server (pid $PID)"
            kill "$PID"
            rm -f "$PIDFILE"
            exit 0
        fi
        rm -f "$PIDFILE"
    fi

    # Fallback: kill whatever is on the port
    PIDS=$(lsof -iTCP:"$DEV_PORT" -sTCP:LISTEN -t 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        echo ":: stopping process on port $DEV_PORT (pid $PIDS)"
        echo "$PIDS" | xargs kill
    else
        echo ":: no dev server running"
    fi

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

    ## Dev server (singleton)
    Multiple agents share one dev server on port 4000. Commands:
    - `just dev`        — start if not running, exit 0 if already up (safe to call repeatedly)
    - `just dev-status` — pid, port, uptime, memory, HTTP health check (exit 1 if down)
    - `just dev-log`    — last 50 lines of server output (pass N for more: `just dev-log 200`)
    - `just dev-down`   — stop the dev server
    Server logs to .dev.log, PID tracked in .dev.pid. Both gitignored.

    ## Browser testing (Playwright MCP)
    .mcp.json at project root configures Playwright MCP for all Claude Code instances.
    Agents can test the running app without human QA:
    1. Ensure dev server is up: `just dev` (singleton, safe from any agent)
    2. Use Playwright MCP tools: browser_navigate, browser_snapshot, browser_click, etc.
    3. Playwright uses accessibility snapshots (structured data, not screenshots) — works headless
    4. QA gate tickets (T-XXX-XX-browser-qa) at the end of each story verify the UI works

    For interactive dev sessions with a visible browser, use `claude --chrome` instead.

    First-time setup: `npx playwright install --with-deps chromium`

    ## Task management
    - Tickets: docs/active/tickets/ (YAML frontmatter, lisa DAG)
    - Epics: docs/active/epics/ (ongoing health goals, not task-bound)
    - Stories: docs/active/stories/ (feature groupings)
    - `lisa status` — see DAG, waves, what's ready
    - `lisa validate` — check for cycles or missing deps
    - Max 2 concurrent tickets. RDSPI workflow (6 phases per ticket).
    - `lisa loop` / `just work` — launches Zellij with Claude Code agents in panes
      Lisa assigns ready tickets to agents, tracks phase transitions, serializes commits.
      Each agent is a `claude --dangerously-skip-permissions` session in its own pane.
      Agents inherit .mcp.json (Playwright MCP) automatically.

    ## Conventions
    - Ash resources are source of truth — business logic in resources, not controllers
    - Named actions: :create_from_online_booking, :complete_job (not :create, :update)
    - Multi-tenancy first: Company/User set up before any domain resources
    - Security tests in main suite: tenant isolation, policy enforcement, auth boundaries
    - No separate frontend build — Tailwind + esbuild via Mix tasks, no node_modules
    - Dark theme (pure grayscale, hue 0, saturation 0%). --radius: 0rem (sharp edges)
    - Print: @media print flips to white bg, Oswald 42pt/22pt, tear-off strip at bottom
    - Operator config via runtime env vars (OPERATOR_NAME, OPERATOR_PHONE, etc.)
    - Test targeting: `mix test --stale` (default during implement) — only runs tests whose source deps changed. Full suite (`mix test`) before review. If you changed config/*.exs or mix.exs, run full suite. See CLAUDE.md § "Test Targeting".
    - Test tiers: Tier 1 (ExUnit.Case, async: true, pure functions) > Tier 2 (DataCase, Ash+DB) > Tier 3 (ConnCase, HTTP/LiveView). Default to lowest viable. See docs/knowledge/test-architecture.md.

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
    - SaaS integrations → docs/knowledge/specification.md § "External services — buy, don't build"
    - Deploy/infra      → DEPLOYMENT.md (Fly.io, Neon, Docker, local release, costs)
    - CI/guardrails     → .github/workflows/ci.yml + .githooks/pre-commit
    - RDSPI workflow    → docs/knowledge/rdspi-workflow.md (6 phases, artifact format)
    - Epics (health)    → docs/active/epics/ (9 epics: dev env, deploy, surface, domain, content, first customer, demo, security, integrations)
    CONTEXT

# ---------- overview ----------

[private]
_overview:
    #!/usr/bin/env bash
    set -euo pipefail
    exec claude \
      --allowedTools 'Read,Glob,Grep,Bash(lisa status),Bash(lisa validate),Bash(just dev-status),Bash(just dev-log*),Bash(git log*),Bash(git diff*),Bash(git status*),Bash(mix test*),Edit' \
      -- "$(cat .just/prompts/overview.md)"

# ---------- status-agent ----------

[private]
_status-agent:
    #!/usr/bin/env bash
    set -euo pipefail
    exec claude \
      --dangerously-skip-permissions \
      -- "$(cat .just/prompts/status-agent.md)"

# ---------- commit-agent ----------

[private]
_commit-agent:
    #!/usr/bin/env bash
    set -euo pipefail
    exec claude \
      --dangerously-skip-permissions \
      -- "$(cat .just/prompts/commit-agent.md)"

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

[private]
_test-stale *args='':
    mix test --stale {{ args }}

[private]
_test-file FILE *args='':
    mix test {{ FILE }} {{ args }}

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

# ---------- test-pyramid ----------

[private]
_test-pyramid:
    mix haul.test_pyramid

# ---------- clean ----------

[private]
_clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ":: cleaning build artifacts"
    rm -rf _build deps
    echo ":: done"
