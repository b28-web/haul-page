# T-029-02 Structure: pyramid-reporter

## Files Created

### `lib/mix/tasks/haul/test_pyramid.ex`
Module: `Mix.Tasks.Haul.TestPyramid`

```
use Mix.Task
@shortdoc "Report the test pyramid shape"

def run(_args)          — entry point, calls scan + format + print
def scan_files(dir)     — Path.wildcard, classify, count → [{path, tier, count}]
defp classify(path)     — read first 20 lines, regex match → :unit | :resource | :integration
defp count_tests(path)  — count `test "` lines
def format_report(results) — build the formatted output string
defp bar(pct, max_width) — render █ bar
```

### `test/mix/tasks/haul/test_pyramid_test.exs`
Module: `Mix.Tasks.Haul.TestPyramidTest`

```
use ExUnit.Case, async: true

Tests:
- classify/1 with ExUnit.Case file → :unit
- classify/1 with DataCase file → :resource
- classify/1 with ConnCase file → :integration
- count_tests/1 with known content
- scan_files/1 with temp directory
- format_report/1 output shape
```

## Files Modified

### `justfile`
Add recipe:
```
test-pyramid:
    @just _test-pyramid
```

### `.just/system.just`
Add recipe:
```
[private]
_test-pyramid:
    mix haul.test_pyramid
```

## No Other Changes

No changes to existing modules, configs, or test support files.
