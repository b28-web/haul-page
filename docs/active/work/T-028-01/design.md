# T-028-01 Design: Logic Audit

## Decision

This is a research-only ticket. The deliverable is `audit.md` — a catalog of extractable functions with categorization and prioritization. No code changes.

## Audit Structure Options

### Option A: Flat list sorted by priority
Simple ordered list. Easy to scan but loses context about where functions live.

### Option B: Grouped by source module, tagged by category
Preserves code location context while still categorizing. Each entry includes source, description, purity, coverage, and extraction difficulty.

### Option C: Grouped by extraction category (pure / DB-read / tightly-coupled)
Organizes by actionability — what to extract first. Loses source module grouping.

**Chosen: Option B with category tags.** Acceptance criteria require both source location AND category. Group by source module, tag each with category. Add a summary section at the end sorted by priority.

## Categorization Criteria

Per the ticket:
- **Pure functions** — no side effects, no DB, no external calls. Extract immediately.
- **Logic with DB reads** — reads data but core logic is a transformation. Extract the transformation.
- **Tightly coupled** — interleaved with Ash DSL or socket manipulation. Not worth extracting now.

## Prioritization Criteria

Per the ticket, prioritize by:
1. Number of tests that would move from integration → unit
2. Code clarity improvement (deduplication, single responsibility)

Additional signals:
- Duplicated functions get higher priority (DRY improvement is immediate)
- Functions with zero test coverage get higher priority (adding unit tests = net new coverage)
- Functions already in pure modules but lacking isolated tests (easy wins)

## Extraction Difficulty Scale

- **Trivial** — copy function to new module, update callers. No signature changes.
- **Moderate** — need to separate pure logic from side effects. May require splitting a function.
- **Hard** — deeply interleaved with Ash DSL, socket assigns, or multi-step orchestration.

## Target Numbers

Ticket requires: ≥20 extractable functions, ≥10 pure. Research found 50+ candidates with 35+ pure. Will document all viable candidates and highlight the top 20.

## Downstream Tickets

This audit feeds T-028-02 (extract billing/content logic) and T-028-03 (extract LiveView logic). The audit should clearly indicate which candidates belong to which downstream ticket's scope.
