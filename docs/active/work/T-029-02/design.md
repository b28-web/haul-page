# T-029-02 Design: pyramid-reporter

## Approach

Single-module mix task with pure functions for scanning, classifying, counting, and formatting. No external dependencies. No app.start required.

## Design Decisions

### File Discovery
Use `Path.wildcard("test/**/*_test.exs")`. Simple, no dependencies, covers all test files. Excludes `test/support/` naturally since those files don't end in `_test.exs`.

### Tier Classification
Read first ~20 lines of each file, match on `use` declaration:
- `~r/use ExUnit\.Case/` → Tier 1
- `~r/use Haul\.DataCase/` → Tier 2
- `~r/use HaulWeb\.ConnCase/` → Tier 3
- No match → unknown (warn, don't crash)

Why first ~20 lines? The `use` declaration is always near the top. Reading full files is unnecessary.

### Test Counting
Count lines matching `~r/^\s+test\s+"/)` in each file. This captures `test "description" do` patterns. Simple regex, handles indentation.

### Output Format
Follow the ticket's exact format spec with Unicode box-drawing characters and block characters for bars.

### Bar Chart
Scale bars proportionally. Max bar width = 20 chars. Use `█` (full block) character.

### Rejected Alternatives
1. **Running the test suite with `--dry-run`** — too slow, requires app.start, fragile
2. **AST parsing via Code.string_to_quoted** — overkill for simple pattern matching
3. **ExUnit formatter** — requires running tests, not what the ticket asks for

## Module Structure

Single module: `Mix.Tasks.Haul.TestPyramid`

Public API (for testing):
- `scan_files/1` — given a directory, returns list of `{path, tier, test_count}`
- `format_report/1` — given scan results, returns formatted string

This separation makes the task testable at Tier 1 without needing real test files — we can pass in synthetic data.

## Testing Strategy

Tier 1 tests using temporary files:
- Create temp dir with sample test files containing different `use` declarations
- Verify classification logic
- Verify counting logic
- Verify formatting output
