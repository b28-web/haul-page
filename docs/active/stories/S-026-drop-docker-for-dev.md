---
id: S-026
title: drop-docker-for-dev
status: open
epics: [E-014, E-001]
---

## Drop Docker for Dev

Replace Docker-hosted Postgres with native Postgres for local development. Docker Desktop on Apple Silicon consumes ~5.2GB RAM to run a single Postgres 16 container — 20x the app's own footprint. The host already has Postgres 18 installed via brew/mise.

## Scope

- Switch dev/test config to use native Postgres (already at localhost:5432 with postgres:postgres)
- Pin toolchain versions in `.mise.toml` (Elixir, OTP, Postgres, Node)
- Verify full test suite passes on Postgres 18 (Ash schema-per-tenant DDL, migrations)
- Update DEPLOYMENT.md, `mix setup`, and just recipes to remove Docker prerequisite
- Dockerfile is untouched — it's for Fly.io remote builds, not local dev
