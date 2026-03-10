---
id: T-032-01
story: S-032
title: supervised-init-tasks
type: task
status: open
priority: medium
phase: done
depends_on: []
---

## Context

`Application.start/2` calls `Haul.Content.Loader.load!()` and `Haul.Admin.Bootstrap.ensure_admin!()` synchronously before the supervision tree starts. If either fails, the entire app fails to start. These should be supervised tasks that can fail gracefully.

## Acceptance Criteria

- Remove `Content.Loader.load!()` and `Admin.Bootstrap.ensure_admin!()` from `Application.start/2`
- Add them as supervised children in the supervision tree:
  - Use `Task` child specs with `:transient` restart (don't restart after success)
  - Place them after Repo (they need DB) but before Endpoint (optional — content can load after)
- Content loader failure:
  - App starts, logs warning: "Content not loaded — content pages will return 503"
  - `Content.Loader.loaded?/0` returns false
  - Content-dependent routes return 503 until loader succeeds
  - Supervisor retries the loader (exponential backoff)
- Admin bootstrap failure:
  - App starts, logs warning: "Admin bootstrap failed — superadmin panel requires manual setup"
  - Superadmin routes work but show "setup required" if no admin exists
  - Supervisor retries bootstrap
- `test_helper.exs` ensures both init tasks complete before tests run (they should — tasks run fast in test env)
- All 845+ tests pass

## Implementation Notes

- `Task` with `:transient` restart is the right primitive — it runs once, succeeds, and stays down. If it crashes, the supervisor restarts it.
- Alternatively, use a simple GenServer that does the work in `init/1` with `handle_continue/2` for non-blocking init
- Content loader currently uses `persistent_term` — this works fine with supervised init. The `loaded?/0` check is the gate.
- The admin bootstrap creates a DB record — it should be idempotent (check before create), which it likely already is
