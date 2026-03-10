---
id: T-026-01
story: S-026
title: native-postgres-switch
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

Docker Desktop consumes ~5.2GB RAM on Apple Silicon to run a single Postgres 16 container. The host already has Postgres 18 installed via brew/mise. The dev/test config already points at `localhost:5432` with `postgres:postgres` credentials. This is mostly a documentation and toolchain-pinning change.

## Acceptance Criteria

- Create `.mise.toml` pinning: Elixir, Erlang/OTP, Postgres, Node versions
- `mix setup` works without Docker running:
  - Creates dev and test databases on native Postgres
  - Runs migrations
  - Seeds content
- Dev server (`mix phx.server`) connects to native Postgres
- Full test suite passes on Postgres 18 (845+ tests, 0 failures)
- Verify Ash schema-per-tenant DDL works on PG 18:
  - `CREATE SCHEMA`, `SET search_path`, `DROP SCHEMA CASCADE`
  - Tenant isolation tests pass
  - Multi-tenant content seeding works
- `just dev` recipe works without Docker
- Document any PG 16→18 behavioral differences encountered

## Implementation Notes

- Config already uses `localhost:5432`, `postgres:postgres` — likely no config changes needed
- The haul-pg Docker container name is referenced nowhere in code or config (only in the footprint report)
- Main risk: PG 18 may have stricter SQL behavior or different default settings that affect Ash-generated queries
- Check `synchronous_commit`, `max_connections`, `shared_buffers` defaults on native PG vs Docker PG
