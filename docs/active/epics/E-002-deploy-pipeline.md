---
id: E-002
title: deploy-pipeline
status: active
---

## Deploy Pipeline Health

Every push to main should result in a working production deploy. The pipeline must be fast, reliable, and cheap.

## Ongoing concerns

- CI passes: tests, format, credo, dialyzer
- Docker build produces a small, correct release image
- Fly.io deploy succeeds with migrations running before app start
- Scale-to-zero works — cold start stays under 3 seconds
- Secrets management via `fly secrets` — no credentials in code or image
- Neon Postgres connection stays healthy across scale-to-zero wake-ups
- Deploy cost stays within budget (< $15/mo per operator)
