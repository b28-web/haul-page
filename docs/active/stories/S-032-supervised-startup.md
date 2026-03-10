---
id: S-032
title: supervised-startup
status: open
epics: [E-016]
---

## Supervised Startup

`Application.start/2` runs two blocking calls before the supervision tree starts:
- `Haul.Content.Loader.load!()` — loads JSON content into `persistent_term`
- `Haul.Admin.Bootstrap.ensure_admin!()` — ensures a superadmin exists

If either crashes, the app doesn't start. If either is slow, startup blocks. The Zen of Erlang says: stable things at the root of the supervision tree, fragile things at the leaves. Init code that can fail should be a supervised worker.

## Scope

- Move `Content.Loader.load!()` into a supervised worker (or `Task` child) that runs on startup
  - If it fails, the app starts without content (graceful degradation)
  - Supervisor can retry the load
  - Content pages return a "loading" or 503 state until content is available
- Move `Admin.Bootstrap.ensure_admin!()` into a supervised startup task
  - If it fails, superadmin panel is unavailable but the app runs
  - Log a clear warning so operators know to fix it
- Add intermediate supervisor grouping if beneficial:
  - Core: Repo, PubSub, Endpoint (must start)
  - Background: Oban, RateLimiter, DNSCluster (can restart independently)
  - Init: ContentLoader, AdminBootstrap (run-once tasks, can fail gracefully)

## Tickets

- T-032-01: supervised-init-tasks — move Content.Loader and Admin.Bootstrap into supervised startup tasks
- T-032-02: supervision-tree-review — evaluate whether intermediate supervisors are warranted; add if the grouping improves fault isolation

## Acceptance criteria

- App starts even if content loading fails (returns 503 for content pages until loaded)
- App starts even if admin bootstrap fails (logs warning, superadmin panel shows "setup required")
- No blocking calls in `Application.start/2` before `Supervisor.start_link`
- Existing tests pass — startup tasks complete before test suite runs (use `Application.ensure_all_started` in test_helper)
