---
id: T-030-01
story: S-030
title: audit-error-handling
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

The codebase has defensive error handling patterns inherited from OOP thinking. Before changing anything, audit every `try/rescue`, `rescue`, and error-swallowing pattern to classify it correctly. Some rescues are legitimate (boundary code handling user input or external API failures). Others hide bugs.

## Acceptance Criteria

- Produce `docs/active/work/T-030-01/audit.md` cataloging every error handling site in `lib/`:
  - Every `try/rescue` and `rescue` block
  - Every worker that returns `:ok` on failure
  - Every function that returns `{:ok, default}` on error (e.g., `{:ok, []}` when API fails)
- Classify each site as:
  - **Remove** — defensive rescue that hides bugs. Let it crash.
  - **Narrow** — rescue is valid but too broad. Catch specific exceptions only.
  - **Keep** — legitimate boundary code (user input validation, external API error handling, expected failure modes).
  - **Fix return** — worker or function that should propagate errors instead of swallowing them.
- For each "remove" or "narrow" site, note what the calling code expects and whether tests assert on the current behavior
- No code changes — this is research

## Implementation Notes

- Search for: `rescue`, `try do`, `catch :exit`, `catch _`, `rescue _`, `rescue e in`, `rescue e ->`
- Also check for `with` blocks that have catch-all `else` clauses returning default values
- Pay special attention to Oban workers — they should return `{:ok, result}` or `{:error, reason}`, never bare `:ok` on failure
- The 9 sites identified in the codebase audit (6 rescues + 3 workers) are the starting point, but there may be more
