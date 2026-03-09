# T-024-04 Research: Agent Test Targeting

## Current Test Infrastructure

### Test suite overview
- **746 tests**, 0 failures, 1 excluded (`@moduletag :baml_live`)
- Full suite: ~96 seconds (1.1s async, 95.3s sync)
- Targeted single file (`billing_test.exs`, 30 tests): 0.06 seconds
- Targeted multi-file (accounts + login + signup, 37 tests): ~5 seconds
- Test compilation overhead dominates targeted runs (BEAM VM startup + compile)

### Test file layout
85 test files across three top-level directories:
- `test/haul/` — domain logic (accounts, ai, billing, content, operations, payments, etc.)
- `test/haul_web/` — controllers, LiveViews, plugs, smoke tests
- `test/mix/` — Mix task tests

### Source file layout
116 source files in `lib/` across ~31 directories. Clear domain boundaries:
- `lib/haul/accounts/` → `test/haul/accounts/`
- `lib/haul/ai/` → `test/haul/ai/`
- `lib/haul/billing/` → `test/haul/billing_test.exs`
- `lib/haul/content/` → `test/haul/content/`
- `lib/haul_web/live/` → `test/haul_web/live/`
- etc.

### ExUnit tagging
Only one tag in use: `@moduletag :baml_live` on `test/haul/ai/integration_test.exs` (excluded by default). No domain-based tags exist.

### Existing test infrastructure (from T-024 siblings)
- `test/support/timing_formatter.ex` — per-test + per-file timing via `HAUL_TEST_TIMING=1`
- `test/test_helper.exs` — conditional formatter loading, sandbox setup
- `config/test.exs` — sandbox adapters, fast bcrypt, runtime plug init
- `.just/system.just` — `_test` recipe: `mix test {{ args }}` (pass-through)

### How `mix test` targeting works
Elixir's built-in `mix test` supports:
- File paths: `mix test test/haul/billing_test.exs`
- Directories: `mix test test/haul/accounts/`
- Line numbers: `mix test test/haul/billing_test.exs:42`
- Multiple paths: `mix test path1 path2 path3`
- Tags: `mix test --only tag_name` (requires `@moduletag` or `@tag` in tests)
- Exclude: `mix test --exclude tag_name`

### Module-to-test mapping patterns
The codebase follows a consistent mirroring convention:
- `lib/haul/<domain>/<module>.ex` → `test/haul/<domain>/<module>_test.exs`
- `lib/haul_web/live/<module>.ex` → `test/haul_web/live/<module>_test.exs`
- `lib/haul_web/controllers/<module>.ex` → `test/haul_web/controllers/<module>_test.exs`

Some domain modules have a single aggregated test file (e.g., `lib/haul/billing/` → `test/haul/billing_test.exs`), while others mirror 1:1.

Cross-cutting test files:
- `test/haul/tenant_isolation_test.exs` — should run for any tenant-touching change
- `test/haul_web/smoke_test.exs` — should run for any route change
- QA test files (`*_qa_test.exs`) — browser-level integration, not typically needed for unit changes

### RDSPI workflow file
`docs/knowledge/rdspi-workflow.md` — currently no mention of testing strategy during Implement phase. The ticket asks us to add targeted test guidance there.

### CLAUDE.md
Has conventions section but no test targeting guidance. Agents currently run full suite.

### justfile
`just _test` passes args through to `mix test`. Agents can already do `just _test test/haul/billing_test.exs`.

## Constraints
- No ExUnit tag infrastructure beyond `:baml_live` — adding domain tags to 85 files is high-effort
- File path targeting already works well and is zero-config
- The mapping from source → test is predictable from directory structure
- Compilation overhead is ~1-2s even for targeted runs (unavoidable for BEAM)
- Agents need a reference document, not runtime tooling — they can already run targeted tests

## Key finding
The core need is **documentation + a mapping reference**, not new code. Agents don't know which tests to run because there's no mapping guide. The `mix test` infrastructure already supports everything needed.
