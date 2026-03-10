# T-026-02 Design: verify-and-document

## Decision: minimal surgical edits

T-026-01 already updated most files. Only two files need changes:

### 1. DEPLOYMENT.md — restructure "Local deploy" section

**Current** (lines 53–90): Docker first, native release second.

**New structure:**
```
## Local deploy (test the release locally)

### Native release (recommended)
  - Build and run natively — no Docker needed
  - Uses native Postgres (just pg)

### Docker image (optional — test the production image)
  - docker build + docker run
  - Only for verifying the Fly.io image works locally
```

**Rationale:** The whole point of S-026 is dropping Docker for dev. The deployment doc should lead with the Docker-free path. Docker section stays for people who want to test the exact production image.

### 2. OVERVIEW.md — add decision note

Add to "Decisions made during implementation":
- **Docker Desktop no longer required for dev** — local dev uses Postgres 18 via Homebrew. Docker/Dockerfile stays only for Fly.io remote builders (production deploy).

Also update blockers to remove the T-026-01 WIP note since that work is done.

## Rejected alternatives

**Delete Docker section entirely from DEPLOYMENT.md** — Rejected. The Dockerfile is still used by Fly.io remote builders. Developers may want to test the exact image locally. Keep it as optional.

**Create a separate SETUP.md** — Rejected. CONTRIBUTING.md already has setup instructions. Adding another file would fragment information.

## Verification strategy

Run `mix test` to confirm the test suite still works (this is a docs-only ticket, so tests shouldn't be affected, but we verify anyway). Check `just llm` output to confirm it reads correctly.
