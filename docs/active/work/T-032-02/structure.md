# T-032-02 Structure: Supervision Tree Review

## Changes

### Modified files

1. **`lib/haul/application.ex`** — Add a comment block above the children list documenting the flat tree decision and revisit criteria. No structural changes.

### No new files

This ticket concludes "no change needed." The work artifacts serve as the permanent record.

### No deleted files

## Module boundaries

No new modules. No interface changes. The supervision tree structure is unchanged.

## Comment placement

```elixir
# lib/haul/application.ex — inside start/2, above `children = [`

# Supervision tree: flat :one_for_one
# ─────────────────────────────────────
# All children restart independently. No coupled processes require
# grouped restart (:one_for_all/:rest_for_one). Oban manages its
# own internal supervision. Init tasks are :transient (exit after success).
#
# Revisit (add intermediate supervisors) when:
# - 15+ children, or
# - Coupled processes needing grouped restart, or
# - Stateful GenServers that need isolated restart budgets
#
# Decision: T-032-02 (docs/active/work/T-032-02/)
```

## Ordering

Single change — comment addition. No ordering concerns.
