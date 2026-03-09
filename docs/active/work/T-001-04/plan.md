# T-001-04 Plan: Dockerfile

## Step 1: Generate release files
Run `mix phx.gen.release --docker` to get the release module and overlay scripts. If the generator isn't available or produces unwanted output, create manually:
- `lib/haul/release.ex` — migrate/rollback functions
- `rel/overlays/bin/server` — starts with PHX_SERVER=true
- `rel/overlays/bin/migrate` — runs migrations

**Verify:** Files exist and contain expected content.

## Step 2: Create `rel/overlays/bin/migrate_and_start`
Custom script that chains migrate + server:
```sh
#!/bin/sh
set -eu
bin/migrate
exec bin/server
```
Mark executable.

**Verify:** `chmod +x` applied, script content correct.

## Step 3: Create `.dockerignore`
Exclude build artifacts, dev files, docs, tests, secrets from Docker context.

**Verify:** File exists with expected exclusions.

## Step 4: Create `Dockerfile`
Three-stage build per design.md. ARGs for Elixir/OTP/Debian versions.

**Verify:** `docker build .` succeeds.

## Step 5: Verify image size
Run `docker images` to check final image is under 100MB.

**Verify:** Image size < 100MB.

## Step 6: Test migrate_and_start entrypoint
Verify the release contains the expected binaries and the entrypoint script is present in the image.

**Verify:** `docker run --rm <image> ls bin/` shows `migrate`, `server`, `migrate_and_start`, `haul`.

## Testing Strategy
- **Build test:** `docker build -t haul:test .` must succeed
- **Size test:** `docker images haul:test` shows < 100MB
- **Entrypoint test:** `docker run --rm haul:test ls bin/` shows expected scripts
- **No full integration test** — running the container requires DATABASE_URL and SECRET_KEY_BASE, which is a deploy concern (T-001-05/06), not this ticket

## Commit Plan
1. Commit: release files (lib/haul/release.ex, rel/overlays/)
2. Commit: .dockerignore + Dockerfile + migrate_and_start
