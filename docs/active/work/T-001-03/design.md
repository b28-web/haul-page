# T-001-03 Design: CI Pipeline

## Problem

The quality job is missing `mix dialyzer` (required by AC). Everything else is in place.

## Options

### Option A: Add dialyzer inline to existing quality job

Add `mix dialyzer` as a step after `mix credo --strict` in the existing quality job. Add PLT caching.

**Pros:** Simple, minimal change, one job.
**Cons:** Quality job becomes slower (dialyzer PLT build + analysis can take 3-5 min). Format/credo results delayed until dialyzer finishes too — but they run sequentially anyway.

### Option B: Separate dialyzer into its own job

Create a `dialyzer` job parallel to `quality`. Quality keeps format + credo. Dialyzer gets its own beam setup + cache.

**Pros:** Faster feedback for format/credo failures. Dialyzer failures don't block quick checks.
**Cons:** More YAML, extra beam/deps setup time (mitigated by parallelism), more GHA minutes.

### Option C: Add dialyzer to quality job with separate PLT cache step

Same as Option A but with a dedicated PLT cache step (separate from deps/_build cache) keyed on Elixir+OTP version + mix.lock hash.

**Pros:** Single job, efficient PLT caching, simple.
**Cons:** Sequential execution means format/credo wait on compilation, but that's already the case.

## Decision: Option A with PLT caching (modified Option C)

Rationale:
- The AC explicitly says quality job runs format, credo, dialyzer. Keeping them together matches the spec.
- PLT cache is essential — without it, every CI run rebuilds PLTs from scratch (~3-5 min).
- The quality job already needs `mix deps.get` and compilation. Adding dialyzer is incremental.
- If dialyzer becomes a bottleneck later, splitting into its own job is a trivial refactor.

## PLT Caching Strategy

Dialyzer PLTs live in `priv/plts/` (dialyxir default with config) or `_build/dev/dialyxir_*.plt`. Since MIX_ENV=test in CI, PLTs go to `_build/test/...`.

Better approach: cache `priv/plts/` explicitly. This requires a `dialyxir` config in `mix.exs` to set `plt_local_path` and `plt_core_path`. However, that's a code change beyond the CI file.

Simpler approach: cache `_build` already includes PLTs since dialyxir stores them there by default. The existing `_build` cache should suffice — PLTs are in `_build/test/dialyxir_erlang-28_elixir-1.19_deps-test.plt` and similar. The cache key is `mix-${{ runner.os }}-${{ hashFiles('mix.lock') }}` which is correct since PLTs need rebuilding when deps change.

**Decision:** Use existing cache. No separate PLT cache needed — the `_build` cache already covers PLT files. Add `mix compile` before credo/dialyzer to ensure BEAM files exist.

## Additional Changes

1. Add `mix compile` step to quality job before credo (credo needs compiled modules for accurate analysis).
2. Add `mix dialyzer` step after credo.
3. Quality job needs `mix deps.get` (already present) which pulls dialyxir.

## What's Not Changing

- test job: complete, no changes needed.
- guardrails job: bonus, keep as-is.
- deploy job: keep as-is (later ticket handles Fly.io config).
- Trigger configuration: correct as-is.
- Cache strategy: adequate as-is.
- Version pinning: matches mise.toml.

## Rejected

- **Separate dialyzer job**: Over-engineered for current project size. One quality job is simpler.
- **Custom PLT path config in mix.exs**: Unnecessary complexity. Default PLT location within `_build` is already cached.
- **Removing deploy/guardrails jobs**: Out of scope. They were added intentionally and don't conflict with AC.
