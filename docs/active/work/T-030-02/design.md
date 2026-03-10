# T-030-02 Design — Fix Defensive Rescues

## Decision Summary

Three narrow rescue fixes, each with a different approach based on context.

## Site 1: `resolve_plan_from_session` — Isolate atom conversion

**Chosen approach:** Extract `safe_plan_atom/1` helper that rescues only `ArgumentError` from `String.to_existing_atom/1`.

```elixir
defp resolve_plan_from_session(session) do
  metadata = session["metadata"] || %{}
  case metadata["plan"] do
    plan when is_binary(plan) and plan != "" -> safe_plan_atom(plan)
    _ -> resolve_plan_from_line_items(session)
  end
end

defp safe_plan_atom(plan) do
  String.to_existing_atom(plan)
rescue
  ArgumentError -> :pro
end
```

**Why:** The rescue scope shrinks from the entire function to just the atom conversion. Any `ArgumentError` from other code (bugs) will now propagate instead of being silently masked.

**Rejected:** Using `try` with `String.to_atom/1` — creates atoms from untrusted input.
**Rejected:** Pattern matching against known plans — too brittle, must update when plans change.

## Site 2: `cost_tracker` — Remove rescue entirely

**Chosen approach:** Remove the try/rescue block. Keep only the `case` clause.

```elixir
defp do_record_call(params) do
  cost = estimate_cost(params.model, params.input_tokens, params.output_tokens)
  attrs = %{...}

  result = CostEntry |> Ash.Changeset.for_create(:record, attrs) |> Ash.create()

  case result do
    {:ok, entry} ->
      emit_telemetry(entry)
      check_thresholds(entry)
      {:ok, entry}
    {:error, reason} ->
      Logger.warning("[CostTracker] Failed to record: #{inspect(reason)}")
      {:error, reason}
  end
end
```

**Why:** The `case` already handles all return values from `Ash.create/1`. If something unexpected crashes (pool exhaustion, encoding error), that's a bug that should propagate. Callers already treat cost tracking as fire-and-forget — they don't pattern match on the return value.

**Rejected:** Narrowing to specific DB exceptions — adds complexity for no benefit when callers ignore the return value anyway.

## Site 3: `onboarding seed_content` — Narrow to known seeder exceptions

**Chosen approach:** Narrow the rescue to the specific exceptions that `Seeder.seed!/2` raises.

```elixir
defp seed_content(tenant) do
  summary = Seeder.seed!(tenant, defaults_content_root())
  {:ok, summary}
rescue
  e in [Ash.Error.Invalid, File.Error, YamlElixir.ParsingError, RuntimeError] ->
    {:error, :content_seed, Exception.message(e)}
end
```

**Why:** These four exception types cover all known failure modes of `seed!/2`:
- `Ash.Error.Invalid` — Ash validation/changeset errors
- `File.Error` — missing content files
- `YamlElixir.ParsingError` — malformed YAML
- `RuntimeError` — invalid frontmatter (from `parse_frontmatter!`)

Unexpected exceptions (e.g., `DBConnection.ConnectionError`) will now propagate, revealing real infrastructure issues instead of being silently converted to `{:error, :content_seed, _}`.

**Rejected:** Creating a non-bang `Seeder.seed/2` — requires wrapping every individual resource operation across 5 helper functions. Too large for this ticket.
**Rejected:** Removing rescue entirely — the `with` chain in `run/1` and `signup/1` expects `{:error, :content_seed, _}` tuples. Letting exceptions propagate would break the error flow.
