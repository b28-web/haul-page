# T-029-02 Research: pyramid-reporter

## Objective

Create a mix task that reports the test pyramid shape (Tier 1/2/3 distribution) by parsing test files.

## Existing Mix Tasks

Four mix tasks in `lib/mix/tasks/haul/`:
- `test_email.ex` — 26 lines, simplest pattern. `use Mix.Task`, `@shortdoc`, `def run(args)`.
- `seed_content.ex` — 107 lines, uses `OptionParser`, `@requirements ["app.start"]`.
- `onboard.ex` — 108 lines, interactive prompts.
- `stripe_setup.ex` — 75 lines, data-driven.

All use `Mix.shell().info()` for output. No app.start needed for our task (pure file parsing).

## Test File Classification

Three tiers, detected by `use` declaration:

| Tier | Module | Meaning |
|------|--------|---------|
| 1 | `ExUnit.Case` | Pure functions, no DB, async: true |
| 2 | `Haul.DataCase` | Ash actions + DB, async: false |
| 3 | `HaulWeb.ConnCase` | HTTP/LiveView + full stack, async: false |

## Test File Layout

All test files are in `test/` with `_test.exs` suffix. Subdirectories:
- `test/haul/` — domain tests (accounts, ai, billing, content, etc.)
- `test/haul_web/` — web layer tests (controllers, live, plugs)
- `test/support/` — helpers (DataCase, ConnCase, factories) — NOT test files
- `test/mix/tasks/` — mix task tests

## Detection Strategy

Each test file has exactly one `use` declaration near the top:
- `use ExUnit.Case, async: true` → Tier 1
- `use Haul.DataCase` → Tier 2
- `use HaulWeb.ConnCase` → Tier 3

Edge cases:
- Files importing DataCase helpers but using ExUnit.Case — still Tier 1 (the `use` determines)
- `test_helper.exs` — not a test file, skip
- `test/support/` — not test files, skip

## Test Count Detection

Tests are defined with `test "description" do`. Count occurrences of `test "` in each file.
Also count `describe` blocks if wanted, but ticket only asks for test count.

## Justfile Pattern

Root `justfile` has public recipes delegating to `.just/system.just` private recipes.
New recipe: `test-pyramid` in justfile → `_test-pyramid` in system.just.

## Current Approximate Numbers

~103 test files. ~845 tests total. Distribution roughly:
- Tier 1: ~34 files
- Tier 2: ~25 files
- Tier 3: ~44 files

## Key Constraints

- No app.start needed — pure file parsing, no runtime
- Keep it ~50 lines per ticket spec
- Output format specified in ticket (ASCII bar chart with percentages)
- Tests for the mix task itself should be Tier 1 (ExUnit.Case)
