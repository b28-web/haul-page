---
id: E-013
title: developer-agent-experience
status: active
---

## Developer & Agent Experience

Optimize the development loop for both humans and AI agents. The primary bottleneck today is test suite runtime — 624 tests take ~170 seconds, almost entirely synchronous. Every agent runs `mix test` to validate their work, and with 2 concurrent agents, this creates serialized ~3-minute waits that compound across the DAG.

### Goals

- Test suite runs in under 60 seconds (from ~170s today)
- Agents can run targeted test subsets relevant to their ticket without full-suite overhead
- Visibility into what's slow — per-file and per-test timing data, not guesswork
- Compilation time is not a hidden tax on every agent session
- Test infrastructure doesn't become a bottleneck as the test count grows toward 1000+

### Ongoing concerns

- Many test files likely use `async: false` due to tenant/DB state — investigate which actually need it
- Ash resource compilation is known to be slow — measure its contribution
- Tenant provisioning (schema creation) in tests may be a hidden cost
- Oban testing mode and sandbox checkout patterns affect parallelism
- Agent sessions start cold (no build cache) — first `mix test` pays full compilation cost
- Don't sacrifice test isolation for speed — flaky tests cost more than slow tests
