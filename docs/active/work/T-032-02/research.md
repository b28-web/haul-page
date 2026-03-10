# T-032-02 Research: Supervision Tree Review

## Current Supervision Tree

`Haul.Application.start/2` starts a single `Supervisor` with `strategy: :one_for_one` and name `Haul.Supervisor`. All children are at one flat level:

```
Haul.Supervisor (:one_for_one)
├── HaulWeb.Telemetry          — Telemetry poller (metrics)
├── Haul.Repo                  — Ecto repo (DB connection pool)
├── Oban                       — Background job processor (has own internal supervisor)
├── DNSCluster                 — Cluster discovery (may be :ignore)
├── Phoenix.PubSub             — PubSub for LiveView
├── Haul.RateLimiter           — ETS-backed GenServer for rate limiting
├── Haul.Content.InitTask      — :transient Task, loads content into persistent_term
├── Haul.Admin.InitTask        — :transient Task, bootstraps superadmin
└── HaulWeb.Endpoint           — Phoenix Endpoint (Cowboy/Bandit HTTP server)
```

Total: 9 children.

## Child Categories

### Core infrastructure (must stay up for anything to work)
- `Haul.Repo` — DB pool. Everything depends on this.
- `Phoenix.PubSub` — LiveView channel communication.
- `HaulWeb.Endpoint` — HTTP server. The app is useless without it.
- `HaulWeb.Telemetry` — Metrics. Low-impact if it dies, but core infra.

### Background services (can restart independently)
- `Oban` — Has its own supervision tree internally. Manages worker queues, pruning, etc.
- `Haul.RateLimiter` — GenServer with ETS table. If it crashes, ETS table is lost and rate limits reset. Recovers on restart.
- `DNSCluster` — Cluster node discovery. :ignore in dev/test.

### Init tasks (run-once, :transient)
- `Haul.Content.InitTask` — Loads content from DB into persistent_term. Exits normally after success. :transient restart means it only restarts on crash.
- `Haul.Admin.InitTask` — Creates superadmin if missing. Same pattern.

## Behavior Under :one_for_one

With `:one_for_one`, each child restarts independently when it crashes. No child crash affects any other child. This means:
- If RateLimiter crashes, only RateLimiter restarts. Repo, Endpoint, Oban all unaffected.
- If an init task crashes, it retries. No other child disturbed.
- If Repo crashes, the pool restarts but other children are unaffected (they'll get DB errors until pool recovers).

## Key Observations

1. **No process interdependencies require grouped restart.** There's no case where "if A dies, B and C must also restart." The children are independent.

2. **Oban has its own supervision tree.** It manages its own workers, queues, and pruning. Wrapping it in another supervisor adds nothing.

3. **Init tasks are :transient.** They self-terminate after success. An intermediate supervisor would just be a wrapper around a Task that exits in <1 second.

4. **RateLimiter state loss is acceptable.** It's an ETS table of recent request timestamps. Losing it means rate limits reset — benign.

5. **9 children is modest.** OTP applications commonly have 10-20+ flat children. The supervision tree becomes unwieldy at ~20+ children or when restart strategies need to differ per group.

6. **No :one_for_all or :rest_for_one need.** These strategies are for tightly coupled groups (e.g., a registry + dynamic supervisor, or a pipeline where later stages depend on earlier ones). Nothing here has that relationship.

## Restart Intensity

Default supervisor `max_restarts` is 3 in 5 seconds. With 9 children, if any 4 crash within 5 seconds, the supervisor itself crashes and takes down the application. This is actually fine — if 4 children crash in 5 seconds, something is seriously wrong (DB down, network failure), and a full restart is appropriate.

## What Would Intermediate Supervisors Look Like?

```
Haul.Supervisor (:one_for_one)
├── Haul.CoreSupervisor (:one_for_one)
│   ├── HaulWeb.Telemetry
│   ├── Haul.Repo
│   ├── Phoenix.PubSub
│   └── HaulWeb.Endpoint
├── Haul.BackgroundSupervisor (:one_for_one)
│   ├── Oban
│   ├── DNSCluster
│   └── Haul.RateLimiter
└── Haul.InitSupervisor (:one_for_one)
    ├── Haul.Content.InitTask
    └── Haul.Admin.InitTask
```

This adds 3 modules and changes nothing about fault isolation because all levels use :one_for_one. The only benefit would be separate `max_restarts` budgets per group, which is not currently needed.

## Files Relevant to This Ticket

- `lib/haul/application.ex` — The supervision tree definition
- `lib/haul/content/init_task.ex` — Content init task
- `lib/haul/admin/init_task.ex` — Admin init task
- `lib/haul/rate_limiter.ex` — Rate limiter GenServer
- `config/runtime.exs` — Oban and DNS cluster config
