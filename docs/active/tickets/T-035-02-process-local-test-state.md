---
id: T-035-02
story: S-035
title: process-local-test-state
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

Several test files are forced to `async: false` not because they need serial DB access, but because they use global state that isn't process-safe:

1. **Rate limiter ETS** — `clear_rate_limits/0` calls `:ets.delete_all_objects/1` on a global table. If test A clears the table while test B is checking a rate limit, test B gets a false result.
2. **ChatSandbox** — uses process dictionary or global ETS for AI mock state. If two chat tests run concurrently, they may interfere.

Making these process-local unlocks `async: true` for files that currently can't use it.

## Acceptance Criteria

- **Rate limiter:** rate limit checks use `{pid, key}` or `{test_ref, key}` as ETS keys in test mode, so each test process has isolated rate limit state. `clear_rate_limits/0` only clears entries for the calling process.
- **ChatSandbox:** adopt the caller-key pattern (like Mox uses) so each test process gets isolated mock expectations. Concurrent tests can set different ChatSandbox responses without interference.
- At least 5 test files that currently use `clear_rate_limits/0` or `ChatSandbox` can be flipped to `async: true` without flaky failures
- Run `mix test` 5 times with different seeds to verify no async interference
- Document the patterns in `docs/knowledge/test-architecture.md`

## Implementation Notes

### Rate limiter

The rate limiter likely uses ETS with keys like `{ip, endpoint}`. In test mode, prefix keys with `self()` or a test-specific ref:

```elixir
# In rate_limiter.ex
defp rate_key(ip, endpoint) do
  if Application.compile_env(:haul, :env) == :test do
    {self(), ip, endpoint}
  else
    {ip, endpoint}
  end
end
```

Or cleaner: make `clear_rate_limits/0` accept a scope:
```elixir
def clear_rate_limits(pid \\ :all) do
  case pid do
    :all -> :ets.delete_all_objects(@table)
    pid -> :ets.match_delete(@table, {{pid, :_, :_}, :_})
  end
end
```

### ChatSandbox

Follow the Mox pattern — use `$callers` to allow the test process's expectations to be visible to spawned processes (like LiveView processes):

```elixir
defmodule Haul.AI.ChatSandbox do
  def set_response(response) do
    Process.put(:chat_sandbox_response, response)
  end

  def get_response do
    Process.get(:chat_sandbox_response) ||
      find_caller_response()
  end

  defp find_caller_response do
    Enum.find_value(Process.get(:"$callers", []), fn caller ->
      Process.info(caller, :dictionary)
      |> elem(1)
      |> Keyword.get(:chat_sandbox_response)
    end)
  end
end
```

### Verification

After making changes, run the previously-sync files with `async: true` and verify:
```bash
mix test --seed 0
mix test --seed 12345
mix test --seed 99999
```

## Risks

- The `$callers` chain lookup adds a small overhead per AI call in tests — acceptable since it's test-only
- If the rate limiter is used in a GenServer (not the request process), `self()` will be the GenServer PID, not the test PID — use `$callers` there too
- Changing ETS key structure requires updating all rate limiter query patterns
