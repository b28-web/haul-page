# T-026-02 Plan: verify-and-document

## Steps

### Step 1: Update DEPLOYMENT.md "Local deploy" section

Replace lines 53–90 with restructured content:
- Native release first (recommended), with `just pg` prerequisite
- Docker image second (optional), for testing Fly.io image

### Step 2: Update OVERVIEW.md

- Add decision note: Docker Desktop no longer required for dev
- Update T-026-01 blocker entry to reflect completion

### Step 3: Verify `just llm` output

Run `just llm` and confirm:
- No Docker-for-dev references
- `.mise.toml` mentioned as toolchain source
- Native Postgres 18 documented
- `just pg` commands listed

### Step 4: Run test suite

Run `mix test` to confirm nothing is broken (docs-only change, but verify).

## Testing strategy

- No unit tests needed (documentation-only changes)
- Verification is manual: read the updated docs, run `just llm`, run `mix test`
- Full suite run before review phase
