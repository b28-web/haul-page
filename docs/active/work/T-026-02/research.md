# T-026-02 Research: verify-and-document

## Scope

T-026-02 is a documentation-only ticket. T-026-01 did the actual Postgres switch (Homebrew PG 18, just recipes, config verification). This ticket updates all developer-facing docs to reflect the new setup and verifies the fresh clone workflow.

## Current state of files

### DEPLOYMENT.md

Lines 53–90: "Local deploy" section currently leads with Docker (`docker build`, `docker run`), then offers native release as an afterthought ("Or without Docker"). This needs to be restructured — Docker is now only for testing the production image, not for running Postgres.

The rest of DEPLOYMENT.md (production deploy, Neon, migrations, monitoring, cost) is fine — no Docker assumptions for dev.

### .just/system.just — `_llm` recipe

Already updated by T-026-01 (line 263):
- `Postgres 18 local dev (brew), Neon serverless in prod`
- Lines 305–310: full `## Postgres (native, no Docker)` section
- Line 359: `Local dev uses Postgres 18; CI uses 16. Backward-compatible.`
- No Docker-for-dev references remain

**Verdict: _llm is already correct. Just needs verification, no edits.**

### README.md

Already updated by T-026-01:
- Quick start: `brew install postgresql@18` → `mise install` → `just pg` → `just dev`
- No Docker references for dev setup
- Commands section shows `just pg`

**Verdict: already correct.**

### CONTRIBUTING.md

Already updated by T-026-01:
- Setup section: brew PG → mise install → just pg → mix setup
- No Docker references anywhere

**Verdict: already correct.**

### justfile

Already updated by T-026-01:
- `pg`, `pg-stop`, `pg-status` public recipes exposed
- No Docker-for-dev recipes

**Verdict: already correct.**

### mise.toml

Has comment documenting PG 18 via Homebrew (not mise, due to uuid-ossp build issues).

### OVERVIEW.md

"Blockers & risks" mentions T-026-01 uncommitted WIP. "Decisions made" section does not yet note that Docker Desktop is no longer required for dev. This needs updating per acceptance criteria.

## Files that need changes

| File | Change needed |
|------|---------------|
| `DEPLOYMENT.md` | Restructure "Local deploy" section: lead with native release, make Docker optional for image testing |
| `docs/active/OVERVIEW.md` | Add decision: Docker Desktop no longer required for dev |

## Files already updated (by T-026-01, just verify)

| File | Status |
|------|--------|
| `.just/system.just` `_llm` | Correct — no Docker-for-dev refs |
| `README.md` | Correct — brew PG quick start |
| `CONTRIBUTING.md` | Correct — brew PG setup |
| `justfile` | Correct — pg recipes exposed |

## Verification needed

- Fresh clone workflow: `mise install && mix setup && mix test`
- Cannot actually test fresh clone in this session, but can verify all prereq checks exist in `_setup` recipe
- `_setup` already checks: elixir present, psql present, pg_isready
