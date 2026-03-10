# T-026-02 Review: verify-and-document

## Summary

Documentation-only ticket. Updated developer-facing docs to reflect the native Postgres switch completed in T-026-01. Docker is no longer a prerequisite for local development.

## Changes

### Files modified

| File | Change |
|------|--------|
| `DEPLOYMENT.md` | Restructured "Local deploy" section: native release first (recommended), Docker image second (optional) |
| `docs/active/OVERVIEW.md` | Added decision note: Docker Desktop no longer required for dev |

### Files verified (no changes needed — already correct from T-026-01)

| File | Status |
|------|--------|
| `.just/system.just` `_llm` recipe | Correct: "Postgres (native, no Docker)" section, PG 18 documented |
| `README.md` | Correct: quick start uses `brew install postgresql@18` + `just pg` |
| `CONTRIBUTING.md` | Correct: setup uses brew PG + `just pg` + `mix setup` |
| `justfile` | Correct: `pg`, `pg-stop`, `pg-status` recipes exposed |

## Acceptance criteria status

- [x] DEPLOYMENT.md: "Local deploy" no longer assumes Docker for Postgres
- [x] DEPLOYMENT.md: Native Postgres setup leads (with link to CONTRIBUTING.md)
- [x] DEPLOYMENT.md: Docker instructions kept only for "test the release image locally" (optional)
- [x] `just llm` output reflects: no Docker dep, `.mise.toml` as toolchain source, native PG 18
- [x] Just recipes: no Docker-for-dev recipes exist (only `deploy` uses Docker via Fly remote builders)
- [x] OVERVIEW.md: decision added — Docker Desktop no longer required for dev
- [ ] Fresh clone verification (`mise install && mix setup && mix test`): cannot test fresh clone in-session, but `_setup` recipe has all prerequisite checks (elixir, psql, pg_isready)

## Test results

```
mix test
845 tests, 12 failures (1 excluded)
Finished in 48.6 seconds
```

All 12 failures are pre-existing from T-025-01 uncommitted WIP (setup_all migration partially applied). Documented in OVERVIEW.md blockers. No new failures from this ticket's changes.

## Test coverage

N/A — documentation-only ticket. No source code changed.

## Open concerns

1. **Fresh clone workflow not verified end-to-end** — would require a clean environment. The `_setup` recipe checks prerequisites (elixir, psql, pg_isready) and the documented flow (`brew install postgresql@18` → `mise install` → `just pg` → `just dev`) is consistent across README.md, CONTRIBUTING.md, and DEPLOYMENT.md.

2. **T-025-01 WIP still breaks tests** — 12 failures from partially-applied setup_all migration. Unrelated to this ticket but noted for completeness.
