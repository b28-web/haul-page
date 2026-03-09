# T-024-02 Design: Timing Analysis

## Problem Statement

Test suite takes 173s wall clock. 97% of that time is in 55 sync files. The two root causes are:
1. **Redundant per-test setup** — tenant provisioning repeated for every test (51% of runtime)
2. **Unavoidable sleeps** — chat extraction debounce waits (21% of runtime)

## Approach: Analysis Document

This is a spike ticket. The output is `analysis.md` — a diagnostic report that becomes the roadmap for T-024-03 (implementation). No code changes.

### Analysis Structure

The analysis document needs to answer four questions:

1. **Where does the time go?** — Categorized breakdown with per-file and per-test data
2. **What's fixable?** — Prioritized list of changes with estimated savings
3. **What's inherent?** — Tests that are slow by nature (chat streaming, multi-tenant isolation)
4. **What's the projected runtime?** — Estimated time after each tier of fixes

### Categorization Framework

**Tier 1 — Setup deduplication (easy, high impact):**
Move `create_authenticated_context()` and tenant provisioning from per-test `setup` to `setup_all` or describe-level `setup` blocks. Tests that only read tenant state (most admin LiveView tests) can share one provisioned tenant.

Estimated savings: 40-60s (14 files × 2-4s each).

**Tier 2 — Async conversion (medium, moderate impact):**
Files that are `async: false` but don't actually need it. Some DataCase tests could use Ecto sandbox `:auto` mode. Some ExUnit.Case tests are sync by default (no `async:` specified).

Estimated savings: 5-10s (depends on parallelism gains).

**Tier 3 — Sleep reduction (hard, moderate impact):**
Chat tests use 1500ms sleeps for extraction debounce. Could be reduced by:
- Making extraction debounce configurable (shorter in test)
- Using `assert_receive`/`refute_receive` with timeouts instead of fixed sleeps
- Mocking extraction to be synchronous in tests

Estimated savings: 10-20s across chat test files.

**Tier 4 — Structural changes (hard, high impact):**
- Shared test tenant fixture (provision once per suite, not per file)
- Parallel test partitioning (CI sharding)
- Lazy tenant provisioning (only create schema when test actually writes)

Estimated savings: 20-40s but requires significant refactoring.

### What Was Rejected

**Option: Switch all tests to async.** Not viable — tenant schema creation/deletion is global PostgreSQL state, not sandboxable. Ecto sandbox only isolates row-level data within a schema.

**Option: In-memory test database.** Not viable — Ash/AshPostgres relies heavily on PostgreSQL-specific features (schemas, migrations, policies).

**Option: Pre-provisioned test schemas.** Considered but rejected for now — would require a test fixture management system and careful isolation between test files. Worth revisiting in Tier 4 but not a quick win.

### Decision

Produce a detailed `analysis.md` that:
- Lists every file with timing, async status, setup cost, and optimization category
- Provides a prioritized fix list with estimated savings per item
- Projects runtime after Tier 1, Tier 1+2, and Tier 1+2+3 fixes
- Flags files that should NOT be optimized (inherently slow, integration-critical)
