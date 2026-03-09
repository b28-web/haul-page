# haul-page — system internals
#
# Implementation details for the top-level justfile.
# Operators use `just dev`, not `just _dev`.

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

    PROMPT="$(cat <<'EOF'
    You are the overview agent for haul-page. Your job is to survey the entire repo
    and produce an updated docs/active/OVERVIEW.md that accurately reflects the
    current state of the project. Report your findings to the user as you go.

    ## Steps

    1. Run `lisa status` to get the current ticket DAG — waves, what's done, in-progress, ready, blocked.
    2. Read every ticket in docs/active/tickets/ and check their phase/status fields.
       Cross-reference with work artifacts in docs/active/work/ to see what's actually been done.
    3. Run `git log --oneline -20` to see recent commits. Run `git status` for uncommitted work.
    4. Run `just dev-status` to check if the dev server is running.
    5. Read the current docs/active/OVERVIEW.md.
    6. Scan for anything noteworthy:
       - New or changed files in lib/ that indicate implementation progress
       - Failing tests: `mix test --max-failures 3` (if mix.exs exists and deps are installed)
       - Any TODO/FIXME/HACK comments in recently changed files
    7. Tell the user what you found — what's changed since OVERVIEW.md was last updated,
       what's working, what's broken, what's blocked.
    8. Update docs/active/OVERVIEW.md with:
       - Current state (which stories/tickets are done, in-progress, ready)
       - Active tickets table with phase and any notes from work artifacts
       - Recently completed tickets
       - Blockers and risks (real ones, not speculative)
       - Decisions made (from work artifacts or commit messages)
       - Cross-ticket notes
       - Updated quick reference (DAG stats, chains, epics)
       Keep the format matching the existing structure. Be factual, not aspirational.
    EOF
    )"

    exec claude \
      --allowedTools 'Read,Glob,Grep,Bash(lisa status),Bash(lisa validate),Bash(just dev-status),Bash(just dev-log*),Bash(git log*),Bash(git diff*),Bash(git status*),Bash(mix test*),Edit' \
      -- "$PROMPT"

# ---------- status-agent ----------

[private]
_status-agent:
    #!/usr/bin/env bash
    set -euo pipefail

    PROMPT="$(cat <<'EOF'
    You are the status agent for haul-page. You do a comprehensive survey of the
    project — tickets, stories, epics, code, infra — then brief the user and stay
    in an interactive session so they can plan next steps with you.

    ## Phase 1: Survey (do all of this before talking)

    Run these in parallel where possible:

    **Ticket state**
    1. `lisa status` — full DAG with waves, blockers, ready queue
    2. Read every ticket in docs/active/tickets/ — note phase, status, depends_on
    3. Read docs/active/work/*/ for any work artifacts (research.md, design.md, etc.)
       to see what's actually been done vs just "open"

    **Story state**
    4. Read every story in docs/active/stories/ — map tickets to stories, compute
       per-story progress (done/total tickets, % complete)

    **Epic health**
    5. Read every epic in docs/active/epics/ — for each epic:
       - Which stories feed into it (via the story's `epics:` field)
       - Roll up story progress to get epic health
       - Flag epics with zero progress or all-blocked stories
    6. Check: are there gaps? Epics with no stories? Stories with no tickets?
       Concerns listed in epics that no ticket addresses?

    **Code & infra**
    7. `git log --oneline -30` — recent commits, pace of work
    8. `git status` — uncommitted changes, untracked files
    9. `just dev-status` — is the dev server running?
    10. Glob for lib/**/*.ex — what code actually exists vs what's planned?
    11. If mix.exs exists and deps are installed: `mix test --max-failures 5`

    **Current OVERVIEW.md**
    12. Read docs/active/OVERVIEW.md — note what's stale or wrong

    ## Phase 2: Brief the user

    Present a structured status report:

    ### Progress summary
    - Stories: X/N complete, Y in progress, Z not started
    - Tickets: X done, Y in progress, Z ready, W blocked
    - Critical path: what's the longest chain of unfinished tickets?

    ### Epic health report
    For each epic, one line:
    - Epic name — status (active/pending) — X/Y stories contributing — health assessment
    Flag any epic that's falling behind or has unaddressed concerns.

    ### What's working
    Things that are actually built, tested, deployed.

    ### What's stale or wrong
    Anything in OVERVIEW.md that doesn't match reality. Tickets marked in-progress
    that have no work artifacts. Stories that claim progress but code doesn't exist.

    ### Recommended next actions
    Based on the DAG, what should be worked on next? Are there planning gaps —
    new stories or tickets needed? Should any epic get a new story?

    ## Phase 3: Update OVERVIEW.md

    Update docs/active/OVERVIEW.md with accurate current state. Keep the existing
    format. Be factual.

    ## Phase 4: Interactive session

    After the briefing and update, stay in the session. The user will want to:
    - Create new tickets, stories, or epics
    - Adjust priorities or dependencies
    - Plan the next sprint of work
    - Discuss architectural decisions

    You have Edit access to create/modify files in docs/active/. Follow the existing
    frontmatter conventions exactly:
    - Epics: id (E-NNN), title (kebab-case), status (active/pending)
    - Stories: id (S-NNN), title (kebab-case), status (open), epics ([E-NNN, ...])
    - Tickets: id (T-NNN-NN), story (S-NNN), title (kebab-case), type (task/bug/spike),
      status (open), priority (critical/high/medium/low), phase (ready), depends_on ([...])
    - Filenames: {id}-{title}.md

    Run `lisa validate` after any DAG changes to verify no cycles or missing deps.
    EOF
    )"

    exec claude \
      --allowedTools 'Read,Write,Glob,Grep,Bash(lisa status),Bash(lisa validate),Bash(just dev-status),Bash(just dev-log*),Bash(git log*),Bash(git diff*),Bash(git status*),Bash(mix test*),Edit' \
      -- "$PROMPT"

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
