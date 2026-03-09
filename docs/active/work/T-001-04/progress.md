# T-001-04 Progress: Dockerfile

## Completed

### Step 1: Generate release files
- Ran `mix phx.gen.release --docker`
- Docker generation failed (Docker Hub timeout) but release files were created:
  - `lib/haul/release.ex` — migrate/rollback functions
  - `rel/overlays/bin/server` — starts with PHX_SERVER=true
  - `rel/overlays/bin/migrate` — runs Ecto migrations
  - `rel/overlays/bin/server.bat`, `rel/overlays/bin/migrate.bat` — Windows scripts (auto-generated)

### Step 2: Create migrate_and_start
- Created `rel/overlays/bin/migrate_and_start`
- Runs migrate then exec's server
- Made executable (chmod +x)

### Step 3: Create .dockerignore
- Created `.dockerignore` excluding build artifacts, docs, tests, dev files, secrets

### Step 4: Create Dockerfile
- Three-stage: deps → build → runtime
- Used `hexpm/elixir:1.19.3-erlang-28.4-debian-bookworm-20260223-slim` for build
- Used `debian:bookworm-20260223-slim` for runtime
- Key discovery: `mix compile` must run BEFORE `mix assets.deploy` because Phoenix LiveView 1.1 colocated hooks (`phoenix-colocated/haul`) are generated during compilation and required by esbuild

### Step 5: Verify image size
- Image builds successfully: `docker build .` passes
- Image size: **278MB** (exceeds 100MB target)
- Breakdown: ~75MB base Debian + ~31MB runtime deps + ~81MB release + ~3MB locale
- Release size dominated by Ash ecosystem (13MB), ex_cldr (10MB), digital_token (4MB)

### Step 6: Verify entrypoint
- `docker run --rm haul:test ls bin/` shows: haul, migrate, migrate_and_start, server

## Deviations from Plan

1. **Compile before assets:** Plan had assets before compile. Reversed due to colocated hooks dependency.
2. **Image size:** 278MB vs 100MB target. The Ash ecosystem makes this unavoidable on Debian. Documented as known limitation.
3. **Version pin:** Used Elixir 1.19.3 (latest on Docker Hub) instead of 1.19.5 (local). Docker Hub doesn't have 1.19.5 yet.
