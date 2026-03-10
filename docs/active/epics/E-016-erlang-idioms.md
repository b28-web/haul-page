---
id: E-016
title: erlang-idioms
status: active
---

## Erlang Idioms

The codebase is well-structured but has patterns that crept in from OOP/GoF thinking rather than Erlang's "let it crash" philosophy. These aren't bugs — they're structural debt that makes the code harder to reason about, harder to debug in production, and subtly fragile in ways that the supervision tree was designed to prevent.

Reference: Fred Hébert's "The Zen of Erlang" — the core principle is that business logic should express what happens when everything goes right. Error recovery is an architectural concern (supervision trees, restart strategies, Oban retries), not an inline concern (try/rescue, error swallowing, defensive nil checks).

### Problems

1. **Defensive programming** — 6 `try/rescue` blocks catching broad exceptions, 3 workers silently swallowing errors. This hides bugs, loses error context, and prevents supervisors/Oban from doing their job.

2. **GoF Strategy pattern via Application.get_env** — 7 adapter modules dispatch to implementations looked up from global config on every call. Works for testing, but it's a singleton registry pattern. Erlang resolves dependencies at supervision tree init time or compile time.

3. **Blocking startup outside supervision tree** — `Content.Loader.load!()` and `Admin.Bootstrap.ensure_admin!()` run synchronously in `Application.start/2`. If they crash, the app doesn't start. If they're slow, startup blocks. These should be supervised workers with fault tolerance.

### Goals

- Business logic reads as the happy path; error handling lives in architecture
- Workers fail openly so Oban retries work correctly
- Adapter resolution happens once (compile-time or boot-time), not per-call
- Startup is resilient — the app starts even if non-critical init fails
- Supervision tree has appropriate intermediate supervisors as the app grows

### Non-goals

- Removing all error handling — boundary code (user input, external APIs) still needs explicit error tuples
- Removing the adapter/behaviour pattern — it's correct for testability; just resolve the lookup once
- Adding complexity for its own sake — only change things that have a concrete benefit
