# T-030-02 Research — Fix Defensive Rescues

## Scope

T-030-01 audit identified 3 "Narrow" rescue sites. This ticket fixes all three.

## Site 1: `billing_webhook_controller.ex:232-246` — `resolve_plan_from_session`

**Current code:**
```elixir
defp resolve_plan_from_session(session) do
  metadata = session["metadata"] || %{}
  case metadata["plan"] do
    plan when is_binary(plan) and plan != "" ->
      String.to_existing_atom(plan)
    _ ->
      resolve_plan_from_line_items(session)
  end
rescue
  ArgumentError -> :pro
end
```

**Problem:** The `rescue ArgumentError` wraps the entire function body. If `resolve_plan_from_line_items/1` or any map access raises `ArgumentError` for a bug, it's silently masked and defaults to `:pro`.

**Intent:** Only `String.to_existing_atom/1` should be rescued — when Stripe sends a plan string that doesn't correspond to a known atom.

**Callers:** Called from `handle_event("checkout.session.completed")`. Return value used as `subscription_plan` in company update. Only valid values: `:starter`, `:pro`, `:growth`.

**Tests:** `test/haul_web/controllers/billing_webhook_controller_test.exs` — no tests for invalid plan metadata.

## Site 2: `ai/cost_tracker.ex:53-73` — `do_record_call`

**Current code:**
```elixir
try do
  result = CostEntry |> Ash.Changeset.for_create(:record, attrs) |> Ash.create()
  case result do
    {:ok, entry} -> ...
    {:error, reason} -> ...
  end
rescue
  e ->
    Logger.warning("[CostTracker] Failed to record (rescued): #{Exception.message(e)}")
    {:error, :recording_failed}
end
```

**Problem:** The `case` already handles `{:ok, _}` and `{:error, _}`. The rescue only fires on unexpected crashes (pool exhaustion, encoding errors). These are bugs that should propagate.

**Design intent:** Module doc says "All recording operations are non-fatal — if persistence fails, the caller's operation is unaffected." However, the `record_call/1` public API already returns `{:error, _}` — callers don't crash on errors.

**Callers:**
- `record_baml_call/4` delegates to `record_call/1` — return value unused by callers
- Direct `record_call/1` usage in chat/provisioner — also fire-and-forget

**Tests:** `test/haul/ai/cost_tracker_test.exs` — tests the happy path. No error path tests.

## Site 3: `onboarding.ex:149-155` — `seed_content`

**Current code:**
```elixir
defp seed_content(tenant) do
  try do
    summary = Seeder.seed!(tenant, defaults_content_root())
    {:ok, summary}
  rescue
    e -> {:error, :content_seed, Exception.message(e)}
  end
end
```

**Problem:** `Seeder.seed!/1` uses bang functions (`Ash.create!`, `Ash.update!`, `File.read!`, `YamlElixir.read_from_file!`). The broad rescue hides unexpected failures.

**What `seed!` can raise:**
- `Ash.Error.Invalid` — validation failures on create/update
- `File.Error` — missing content files
- `YamlElixir.ParsingError` — malformed YAML
- `RuntimeError` — invalid frontmatter format (from `parse_frontmatter!`)

**Callers:** Used in `with` chains in `run/1` and `signup/1`. Pattern matches `{:error, :content_seed, _}`.

**Option: non-bang Seeder.seed/2:** Does not exist. The seeder only has `seed!/2`. Creating a non-bang version would require wrapping every individual resource operation — larger change than this ticket warrants.

**Tests:** `test/haul/onboarding_test.exs` — tests full onboarding flow but not seed failure paths specifically.

## Existing test files to check

- `test/haul_web/controllers/billing_webhook_controller_test.exs`
- `test/haul/ai/cost_tracker_test.exs` (modified in git status — has pending changes)
- `test/haul/onboarding_test.exs`
