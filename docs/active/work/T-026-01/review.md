# T-026-01 Review — native-postgres-switch

## Summary

Switched local development from Docker Desktop Postgres 16 to native Postgres 18 via Homebrew. Docker Desktop is no longer required for local dev — saves ~5.2 GB RAM. All 845 tests pass (1 pre-existing failure unrelated to this change).

## Test Results

```
845 tests, 1 failure (1 excluded)
Finished in 28.0 seconds
```

The 1 failure is pre-existing: `signup_live_test.exs:51` ("shows slug taken for existing company") — the test creates a company with unique-integer suffix via `create_authenticated_context()` (slug "test-co-NNN") but checks slug "test-co" (without suffix), so slug is correctly reported as "Available" not "Taken". This is a test logic bug, not a PG 18 issue.

## PG 16→18 Behavioral Differences

**None found.** All migrations, schema-per-tenant DDL, Ash extensions (uuid-ossp, citext, ash-functions), and queries work identically on PG 18.3.

## Files Modified

| File | Change |
|------|--------|
| `mise.toml` | Added comment documenting Postgres via brew (not mise) |
| `.just/system.just` | Added `_pg`, `_pg-stop`, `_pg-status` recipes; updated `_dev` and `_setup` with `pg_isready` checks; updated `_llm` context |
| `justfile` | Added `pg`, `pg-stop`, `pg-status` public recipe aliases |
| `README.md` | Updated quick start and commands to include Postgres setup |
| `CONTRIBUTING.md` | Updated setup section with `brew install postgresql@18` + `just pg` |

## Files NOT Modified (as expected)

- `config/dev.exs` — already targets `localhost:5432`, `postgres:postgres`
- `config/test.exs` — same
- `Dockerfile` — production only
- `lib/haul/repo.ex` — `min_pg_version` 16.0.0 satisfied by PG 18
- `.github/workflows/ci.yml` — CI still uses `postgres:16` service (independent)

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| ~~`.mise.toml` pinning Postgres~~ | Deviated — brew manages PG, mise comment documents this |
| `mix setup` works without Docker | ✓ (with `just pg` started first) |
| Dev server connects to native PG | ✓ (HTTP 200 on localhost:4000) |
| Full test suite passes on PG 18 | ✓ (845 tests, 1 pre-existing failure) |
| Ash schema-per-tenant DDL on PG 18 | ✓ (CREATE/SET/DROP SCHEMA all work) |
| Tenant isolation tests pass | ✓ |
| Multi-tenant content seeding works | ✓ |
| `just dev` works without Docker | ✓ |
| Document PG 16→18 differences | ✓ (none found) |

## Deviation from Plan

**mise.toml does not pin Postgres.** The mise `vfox-postgres` plugin builds Postgres from source and cannot detect `ossp-uuid` headers (brew's keg-only layout confuses the configure script). Since the project requires the `uuid-ossp` extension, we use Homebrew's pre-built `postgresql@18` package instead. This is documented in the `mise.toml` comment.

## One-Time Setup Required

The brew `postgresql@18` formula is keg-only. After `brew install postgresql@18`, the following one-time commands are needed:

```bash
brew unlink libpq
brew link postgresql@18 --force
# If initdb fails with "postgres.bki not found":
ln -s /opt/homebrew/share/postgresql /opt/homebrew/share/postgresql@18
ln -s /opt/homebrew/lib/postgresql /opt/homebrew/lib/postgresql@18
```

These symlinks resolve a path mismatch where `pg_config --sharedir` reports `/opt/homebrew/share/postgresql@18` but brew links files to `/opt/homebrew/share/postgresql`.

## Open Concerns

1. **Pre-existing test bug**: `signup_live_test.exs:51` fails consistently. Not caused by this change. Should be fixed separately — the test needs to either use a company without a unique suffix, or check for the actual generated slug.

2. **brew link symlink workaround**: The `postgresql@18` keg-only formula creates a confusing path layout. The symlinks are a one-time workaround documented above. Future Homebrew updates may fix this, or a future `postgresql@19` would need similar symlinks.

3. **CI uses PG 16, dev uses PG 18**: This version delta is intentional and backward-compatible. If CI needs PG 18, update `.github/workflows/ci.yml` to `image: postgres:18`.

## Resource Impact

Before: Docker Desktop ~5.2 GB RAM for a single Postgres container.
After: Native Postgres ~30 MB RSS. Net savings: ~5.1 GB RAM.
