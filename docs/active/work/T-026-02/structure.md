# T-026-02 Structure: verify-and-document

## Files modified

### 1. `DEPLOYMENT.md` (lines 53–90)

Replace the "Local deploy" section. New structure:

```
## Local deploy (test the release locally)

### Native release (recommended)

Build and run the production release on your machine. Requires native Postgres
(see CONTRIBUTING.md for setup).

```bash
just pg  # ensure Postgres is running

# Build
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release

# Run
DATABASE_URL="..." ... _build/prod/rel/haul/bin/haul start
```

### Docker image (optional)

Test the exact Docker image that Fly.io will deploy. Requires Docker Desktop.

```bash
docker build -t haul-page .
docker run --rm -p 4000:4000 -e ... haul-page
```
```

Key changes:
- Native release moves to first position with "(recommended)" label
- Adds `just pg` reminder before build
- Docker section gets "(optional)" label and notes it's for testing the Fly image
- No other sections of DEPLOYMENT.md change

### 2. `docs/active/OVERVIEW.md`

Two edits:
1. "Decisions made" section: add Docker Desktop no longer required note
2. "Blockers & risks": update T-026-01 entry (work is done, no longer WIP)

## Files NOT modified

- `.just/system.just` — already correct from T-026-01
- `README.md` — already correct from T-026-01
- `CONTRIBUTING.md` — already correct from T-026-01
- `justfile` — already correct from T-026-01
- `mise.toml` — already correct from T-026-01

## No new files created

This is a documentation update only.
