# T-031-01 Plan: compile-env-adapters

## Steps

### Step 1: Add production adapter config to prod.exs

Add all 7 adapter selections to `config/prod.exs`. This ensures production builds compile with the correct adapters embedded.

### Step 2: Remove adapter selections from runtime.exs

Remove the 7 `config :haul, :*_adapter` lines from `config/runtime.exs`. Keep all API keys, secrets, and non-adapter config intact. Simplify conditionals that become empty after adapter line removal.

### Step 3: Convert all 7 modules to compile_env

For each module:
1. Add `@adapter Application.compile_env(...)` after the moduledoc
2. Replace `adapter().fn(args)` with `@adapter.fn(args)`
3. Remove `defp adapter` or inline `Application.get_env` calls

Order: AI → Payments → Billing → SMS → Places → Domains → AI.Chat

### Step 4: Run targeted tests

Run tests for each affected domain to verify sandbox adapters still work:
```bash
mix test test/haul/ai/ test/haul/billing_test.exs test/haul/payments_test.exs \
  test/haul/notifications/ test/haul/places/ test/haul/domains_test.exs \
  test/haul/workers/
```

### Step 5: Run full test suite

```bash
mix test
```

All 845+ tests must pass.

## Testing Strategy

No new tests needed. Existing tests already validate adapter dispatch via sandbox adapters configured in test.exs at compile time. The refactor changes dispatch mechanism (ETS read → compiled attribute) but not behavior.

Verification: full `mix test` confirms no regressions.
