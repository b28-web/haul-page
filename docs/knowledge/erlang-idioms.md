# Erlang/Elixir Idioms for haul-page

Reference: [The Zen of Erlang](https://ferd.ca/the-zen-of-erlang.html) by Fred Hébert.

## Core Principle

**Business logic expresses the happy path. Error recovery is architectural.**

Code should describe what happens when everything goes right. Supervision trees, Oban retries, and process isolation handle what happens when things go wrong. Don't mix the two.

## Error Handling Rules

### Let it crash

Erlang's "let it crash" doesn't mean "don't handle errors." It means: **don't handle errors where they occur if the supervisor can handle them better.**

- **Crash** when the error is unexpected and the process can be restarted cleanly (most cases)
- **Return `{:error, reason}`** at system boundaries (user input, external APIs, inter-process communication)
- **Never** `rescue _` or `rescue e` generically — this hides bugs and loses stack traces

### What to rescue vs. what to let crash

| Situation | Approach | Why |
|-----------|----------|-----|
| External API call fails (Stripe, DNS, S3) | Rescue specific exceptions (e.g., `Req.Error`, `Mint.TransportError`) | These are expected failure modes at system boundaries |
| Ash action fails | Let it crash or return `{:error, changeset}` | If the data is valid and the action fails, that's a bug |
| Oban worker hits an error | Return `{:error, reason}` | Oban retries on error; returning `:ok` silently drops the job |
| Background task fails | Let it crash | Supervisor restarts it; the crash is logged with full context |
| User input is invalid | Return `{:error, changeset}` | Expected case, not exceptional |
| Config is missing at startup | Crash in init | App shouldn't start with broken config — fail fast |

### Anti-patterns we've seen

```elixir
# BAD: Defensive rescue that hides bugs
def record_call(params) do
  try do
    Ash.create(CostEntry, params)
  rescue
    e -> Logger.error("Failed: #{inspect(e)}"); {:error, :recording_failed}
  end
end

# GOOD: Let it crash — the caller or supervisor handles it
def record_call(params) do
  Ash.create!(CostEntry, params)
end

# BAD: Worker swallows errors, Oban can't retry
def perform(%{args: %{"job_id" => id}}) do
  case Ash.get(Job, id) do
    {:ok, job} -> send_email(job)
    {:error, _} -> :ok  # silently drops the job!
  end
end

# GOOD: Worker returns error, Oban retries
def perform(%{args: %{"job_id" => id}}) do
  {:ok, job} = Ash.get(Job, id)  # crashes on not-found — Oban retries
  send_email(job)
end
```

## Adapter Resolution

### Resolve at compile time, not per-call

The GoF Strategy pattern via `Application.get_env` on every call is unnecessary overhead in Elixir. Adapters are determined by config environment (dev/test/prod) and don't change at runtime.

```elixir
# BAD: Runtime lookup on every call (GoF Strategy via singleton registry)
defp adapter, do: Application.get_env(:haul, __MODULE__)[:adapter]

def create_payment(params), do: adapter().create_payment(params)

# GOOD: Compile-time resolution
@adapter Application.compile_env(:haul, [__MODULE__, :adapter], Haul.Payments.Stripe)

def create_payment(params), do: @adapter.create_payment(params)
```

`compile_env` reads config once at compile time. Sandbox adapters are set in `config/test.exs`, real adapters in `config/prod.exs`. Mix recompiles when config changes.

## Supervision Tree

### Stable at root, fragile at leaves

The supervision tree should reflect failure tolerance:
- **Must stay up:** Repo, PubSub, Endpoint — at the root
- **Can restart independently:** Oban, RateLimiter, DNSCluster — as children
- **Run-once tasks:** Content loading, admin bootstrap — as transient supervised tasks

### Don't block startup with fallible init

```elixir
# BAD: Blocking call before supervision tree starts
def start(_type, _args) do
  Content.Loader.load!()  # If this crashes, app doesn't start
  Supervisor.start_link(children, opts)
end

# GOOD: Init as a supervised task
children = [
  Repo,
  {Task, fn -> Content.Loader.load!() end},  # Supervised, can fail and retry
  Endpoint
]
```

## Process Design

- **One process, one concern.** Don't accumulate unrelated state in a GenServer.
- **Use ETS for shared read-heavy data.** `persistent_term` for truly immutable config.
- **Links for codependencies, monitors for observation.** Don't link processes that should fail independently.
- **Process dictionary is a code smell** outside of Logger metadata and test sandboxes.

## Testing Implications

These idioms affect testing:
- Code that crashes on error needs tests that verify it crashes (use `assert_raise` or `catch_exit`)
- Workers that return `{:error, reason}` can be tested for retry behavior
- Compile-time adapter resolution means `config/test.exs` must set sandbox adapters (it already does)
- Supervised init tasks need `Application.ensure_all_started(:haul)` in test_helper.exs (already done)
