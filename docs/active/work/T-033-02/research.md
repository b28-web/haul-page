# T-033-02 Research: Extract Pure Logic

## Audit findings (from T-033-01)

The audit identifies **19 tests** across 3 DataCase files where pure logic is tested through the DB:

| File | Pure tests | What's pure |
|------|-----------|-------------|
| `onboarding_test.exs` | 5 | `derive_slug/1` (4), `site_url/1` (1) |
| `content/seeder_test.exs` | 2 | `parse_frontmatter!/1` (2) |
| `ai/cost_tracker_test.exs` | 12 | `estimate_tokens/1` (3), `estimate_cost/3` (3), `model_for_function/1` (3), `pricing/0` (1), `average_session_cost/0` (1 — zero-entries case), threshold (0 — needs DB) |

## Current code analysis

### Haul.Onboarding (`lib/haul/onboarding.ex`)

- `derive_slug/1` (lines 103-108): Pure string transform. Already `def` (public). 4 tests in `describe "derive_slug/1"` block at lines 127-143.
- `site_url/1` (lines 111-114): Reads `Application.get_env` for `base_domain`, builds URL string. 1 test at lines 145-151.
- Both are already public functions on `Haul.Onboarding`. They're pure — no DB, no side effects.
- The test file (`test/haul/onboarding_test.exs`) uses `Haul.DataCase, async: false` because the `run/1` tests need DB + tenant schema provisioning + cleanup.

### Haul.Content.Seeder (`lib/haul/content/seeder.ex`)

- `parse_frontmatter!/1` (line 175): **Already delegated** to `Haul.Content.Markdown.parse_frontmatter!/1`.
- `Haul.Content.Markdown` already has a full unit test file (`test/haul/content/markdown_test.exs`) with `use ExUnit.Case, async: true` — 5 tests for `parse_frontmatter!` specifically.
- The 2 tests in `seeder_test.exs` at lines 144-169 duplicate this coverage via the delegation. They test the exact same pure function through the same code path.
- **Conclusion:** The seeder frontmatter tests are already covered by `markdown_test.exs`. No extraction needed — these can simply be removed from the seeder test (or left as-is since they're harmless). The audit listed these as "extractable" but the extraction already happened in S-028.

### Haul.AI.CostTracker (`lib/haul/ai/cost_tracker.ex`)

- `estimate_tokens/1` (lines 91-95): Pure math. `max(1, div(String.length(text), 4))`.
- `estimate_cost/3` (lines 100-116): Pure Decimal arithmetic. Reads `pricing()` which calls `Application.get_env`.
- `model_for_function/1` (lines 121-123): Pure map lookup on `@function_models` module attribute.
- `pricing/0` (lines 128-130): `Application.get_env` — pure config read.
- **Already `async: true`!** The test file is `use Haul.DataCase, async: true`. The pure tests (12) already run fast.
- The issue isn't speed — it's tier. These tests use DataCase (which starts the Ecto sandbox) when they don't need it. Moving them to ExUnit.Case is about correctness of test tier, not performance.

### Test categorization in cost_tracker_test.exs

**Pure (no DB needed — 12 tests):**
- `estimate_tokens/1`: 3 tests (lines 14-29)
- `estimate_cost/3`: 3 tests (lines 31-51)
- `model_for_function/1`: 3 tests (lines 53-75)
- `pricing/0`: 1 test (lines 278-287)
- `average_session_cost/0 zero case`: 1 test (lines 272-274) — but this calls `Ash.read!` internally, so actually needs DB
- `daily_total zero case`: 1 test (lines 226-229) — calls `Ash.read!`, needs DB

**Revised pure count: 10 tests** (estimate_tokens 3, estimate_cost 3, model_for_function 3, pricing 1).

**DB-required (remaining 14 tests):**
- `record_call/1`: 3 tests — creates CostEntry via Ash
- `record_baml_call/4`: 2 tests — creates CostEntry
- `session_total/1`: 3 tests — reads CostEntry
- `daily_total/1`: 2 tests — reads CostEntry
- `monthly_total/2`: 1 test — reads CostEntry
- `average_session_cost/0`: 2 tests (1 with data, 1 zero) — reads CostEntry
- `threshold alerts`: 1 test — creates CostEntry + logs

## Existing patterns from S-028

S-028 extracted 8 modules. The pattern: if the pure logic is substantial, create a new module (e.g., `ErrorClassifier`, `ProfileSerializer`). If it's trivial (3 lines), keep it inline and test through the caller.

For this ticket:
- `derive_slug/1` and `site_url/1`: Already public on `Haul.Onboarding`. No new module needed — just move the tests.
- CostTracker pure functions: Already public. No new module needed — split the test file.
- Seeder `parse_frontmatter!`: Already extracted to `Content.Markdown` with unit tests. Done.

## Key finding

**The extraction of pure _code_ is already done.** All the pure functions are already public and well-separated. The work is about extracting pure _tests_ into proper unit test files so they:
1. Use `ExUnit.Case, async: true` instead of `DataCase`
2. Don't start the Ecto sandbox
3. Are classified correctly in the test pyramid

## Files to create/modify

| Action | File | What |
|--------|------|------|
| CREATE | `test/haul/onboarding_unit_test.exs` | 5 tests for derive_slug + site_url |
| MODIFY | `test/haul/onboarding_test.exs` | Remove derive_slug + site_url describe blocks |
| CREATE | `test/haul/ai/cost_tracker_unit_test.exs` | 10 tests for pure functions |
| MODIFY | `test/haul/ai/cost_tracker_test.exs` | Remove pure function describe blocks |
| REMOVE | 2 tests from `test/haul/content/seeder_test.exs` | parse_frontmatter! tests (already in markdown_test.exs) |
