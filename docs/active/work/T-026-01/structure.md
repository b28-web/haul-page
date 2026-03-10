# T-026-01 Structure — native-postgres-switch

## Files Modified

### 1. `mise.toml`
- Add `postgres = "18"` to `[tools]`
- Update comment to mention Postgres version sync

### 2. `.just/system.just`

**New recipes:**

```
_pg          — start Postgres if not running (idempotent)
_pg-stop     — stop Postgres
_pg-status   — show Postgres status (running/stopped, port, data dir)
```

**Modified recipes:**

- `_dev` — add `pg_isready` check at top, print "run `just pg` first" if Postgres is down
- `_setup` — add `pg_isready` check after prerequisite checks, before `mix ecto.setup`
- `_llm` — update "Stack" section to mention mise-managed Postgres for dev

### 3. `justfile`

Add public recipe aliases:
```
pg          := _pg
pg-stop     := _pg-stop
pg-status   := _pg-status
```

### 4. `README.md`

Update "Quick start" section:
```
mise install           # Elixir 1.19 + Erlang/OTP 28 + Postgres 18
just pg                # Start Postgres
just dev               # deps, migrate, start server
```

Update "Commands" section to include `just pg` and friends.

### 5. `CONTRIBUTING.md`

Update "Setup" section:
```bash
# 1. Install toolchain (includes Postgres 18)
mise install

# 2. Start Postgres
just pg

# 3. Install deps and set up database
mix setup

# 4. Start dev server
mix phx.server
```

Remove "Requires Postgres" note — mise handles it now.

## Files NOT Modified

| File | Reason |
|------|--------|
| `config/dev.exs` | Already targets localhost:5432 |
| `config/test.exs` | Already targets localhost:5432 |
| `config/runtime.exs` | Production config, unrelated |
| `Dockerfile` | Production build, unaffected |
| `.dockerignore` | Production build, unaffected |
| `lib/haul/repo.ex` | min_pg_version 16 satisfied by PG 18 |
| `.github/workflows/ci.yml` | CI uses PG 16 service, independent |

## Recipe Design: `_pg`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check if Postgres is already running
if pg_isready -q 2>/dev/null; then
    echo ":: postgres already running"
    exit 0
fi

# Ensure mise-managed postgres is installed
if ! command -v pg_ctl &>/dev/null; then
    echo "error: pg_ctl not found — run 'mise install'"
    exit 1
fi

# Initialize data directory if needed
PGDATA="${PGDATA:-$(pg_config --pkglibdir)/../data}"
# mise postgres typically sets PGDATA via env
if [ ! -d "$PGDATA" ] || [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo ":: initializing postgres data directory"
    initdb -D "$PGDATA" --username=postgres --auth=trust
fi

# Start
echo ":: starting postgres"
pg_ctl -D "$PGDATA" -l "$PGDATA/server.log" start

# Wait for ready
for i in $(seq 1 10); do
    if pg_isready -q 2>/dev/null; then
        echo ":: postgres ready (port 5432)"
        exit 0
    fi
    sleep 0.5
done
echo "error: postgres failed to start — check $PGDATA/server.log"
exit 1
```

Key decisions:
- `--auth=trust` for local dev (no password prompts, matches existing config)
- `--username=postgres` to create the default superuser
- Idempotent: checks `pg_isready` first
- Uses mise's PGDATA if set, otherwise derives from `pg_config`

## Recipe Design: `_pg-stop`

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! pg_isready -q 2>/dev/null; then
    echo ":: postgres not running"
    exit 0
fi

PGDATA="${PGDATA:-$(pg_config --pkglibdir)/../data}"
pg_ctl -D "$PGDATA" stop
echo ":: postgres stopped"
```

## Recipe Design: `_pg-status`

```bash
#!/usr/bin/env bash
set -euo pipefail

if pg_isready -q 2>/dev/null; then
    echo "status:  running"
    echo "port:    5432"
    echo "version: $(psql --version | head -1)"
    PGDATA="${PGDATA:-$(pg_config --pkglibdir)/../data}"
    echo "data:    $PGDATA"
else
    echo "status:  stopped"
    echo "hint:    run 'just pg' to start"
fi
```

## Ordering

1. `mise.toml` — add postgres pin (enables `mise install`)
2. `.just/system.just` — add pg recipes, update _dev and _setup
3. `justfile` — expose pg recipes
4. Verify: `mise install`, `just pg`, `mix ecto.create`, `mix test`
5. `README.md` — update quick start
6. `CONTRIBUTING.md` — update setup instructions
7. `.just/system.just` `_llm` — update context for LLM agents
