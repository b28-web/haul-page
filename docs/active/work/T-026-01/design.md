# T-026-01 Design — native-postgres-switch

## Decision: mise-managed Postgres with justfile lifecycle recipes

### Option A: Homebrew Postgres (`brew install postgresql@18`)

**Pros:**
- Familiar to macOS developers
- `brew services start/stop` for lifecycle
- System-wide installation

**Cons:**
- Not version-pinned per project (brew upgrades globally)
- Conflicts if multiple projects need different PG versions
- Can't be tracked in `mise.toml` alongside Elixir/Erlang
- `brew services` is a separate tool from mise

**Rejected:** Doesn't integrate with the existing mise-based toolchain.

### Option B: mise-managed Postgres (chosen)

**Pros:**
- Single `mise.toml` pins Elixir, Erlang, AND Postgres
- `mise install` sets up everything
- Per-project version isolation
- Consistent with existing toolchain strategy
- `PGDATA` can be project-local or in mise's data dir

**Cons:**
- mise postgres plugin is community-maintained (not official)
- Developers need `mise install` to get Postgres (but they already need it for Elixir)

**Chosen:** Best alignment with existing toolchain. One file, one command.

### Option C: Docker with reduced footprint (OrbStack/Colima)

**Rejected:** The goal is to eliminate Docker dependency entirely for dev. Switching Docker runtimes doesn't remove the abstraction layer.

## Postgres Lifecycle Strategy

### Problem
Current dev recipes (`just dev`, `just setup`) assume Postgres is already running. They don't start or stop it. With Docker Desktop, users started the container manually (or Docker auto-started it).

### Decision: Add `just pg` recipes

Add thin lifecycle recipes to the justfile:

- `just pg` — start Postgres (idempotent, like `just dev`)
- `just pg-stop` — stop Postgres
- `just pg-status` — show Postgres status

The `_dev` recipe will call `pg_isready` and print a helpful message if Postgres isn't running, but NOT auto-start it. Reason: auto-starting a database server silently is surprising behavior. Better to tell the user what to do.

### PGDATA Location

**Option A: Project-local** (`./pgdata/`) — rejected. Clutters project root, large directory, gitignore headache.

**Option B: mise default** — chosen. mise-managed postgres stores data in `~/.local/share/mise/installs/postgres/18/data/`. This is the standard location and doesn't pollute the project.

However, we want a project-specific database cluster to avoid conflicts with other projects. Use a `PGDATA` override pointing to a project-namespaced directory within mise's data area.

**Final decision: Use mise's default data directory.** Since this machine only runs haul-page, there's no conflict concern. The databases (`haul_dev`, `haul_test`) are namespaced by name, not by cluster. If needed later, PGDATA can be overridden.

## mise.toml Changes

```toml
[tools]
erlang = "28"
elixir = "1.19"
postgres = "18"
```

Add postgres pin. The comment about keeping in sync with CI/Dockerfile still applies — CI uses PG 16, which is fine (backward compatible).

## min_pg_version

The repo declares `min_pg_version` as 16.0.0. PG 18 satisfies this. No change needed.

## Documentation Updates

1. **`mise.toml`** — Add `postgres = "18"`
2. **`README.md`** — Update quick start: `mise install` now includes Postgres
3. **`CONTRIBUTING.md`** — Update setup section with `mise install` + `just pg`
4. **`.just/system.just`** — Add `_pg`, `_pg-stop`, `_pg-status` recipes. Update `_setup` to check `pg_isready`. Update `_llm` recipe to mention native Postgres.
5. **`justfile`** — Expose `pg`, `pg-stop`, `pg-status` as public recipes

## CI Impact

None. CI uses `postgres:16` as a GitHub Actions service. This is independent of local dev. No CI changes needed.

## What NOT to Change

- `config/dev.exs` — already correct
- `config/test.exs` — already correct
- `Dockerfile` — production only, stays as-is
- `.dockerignore` — production only, stays as-is
- `lib/haul/repo.ex` — `min_pg_version` 16 is fine (PG 18 > 16)

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| PG 18 behavioral difference breaks tests | Low | Run full suite, document any issues |
| mise postgres plugin instability | Low | Pin exact version, test `mise install` |
| Ash extensions not available on PG 18 | Very low | uuid-ossp and citext are standard contrib |
| Schema-per-tenant DDL fails on PG 18 | Very low | Run tenant isolation tests specifically |
| Developer confusion about Postgres lifecycle | Medium | Clear docs, `just pg` recipe, helpful error messages |

## Verification Plan

1. `mise install` succeeds (Postgres 18 installed)
2. `just pg` starts Postgres, `pg_isready` confirms
3. `mix ecto.create` creates `haul_dev` and `haul_test`
4. `mix ecto.migrate` runs all migrations
5. `mix test` — 845+ tests, 0 failures
6. Specifically verify: tenant isolation tests, content seeding, schema DDL
7. `just dev` starts Phoenix and connects to native Postgres
