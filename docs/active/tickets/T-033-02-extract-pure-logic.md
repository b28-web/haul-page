---
id: T-033-02
story: S-033
title: extract-pure-logic
type: task
status: open
priority: high
phase: done
depends_on: [T-033-01]
---

## Context

Several modules mix pure deterministic logic with DB operations. The tests exercise the pure parts through the DB because the logic isn't separated. This ticket extracts pure functions so they can be unit-tested without touching the DB.

This follows the same pattern as S-028 (Extract Domain Logic) but focuses specifically on modules identified in T-033-01 where DB-coupled tests are testing pure logic.

## Acceptance Criteria

- For each module flagged in the T-033-01 audit as "mock-feasible", extract pure functions into a testable shape
- New unit tests (`ExUnit.Case, async: true`) cover the extracted logic
- Original DataCase tests are trimmed to only test the DB-integration surface
- No net loss in assertion coverage — every assertion removed from a DataCase test has a corresponding unit test
- All tests pass

## Likely extraction targets (confirm with T-033-01 audit)

### `Haul.AI.EditApplier`
- **Pure logic:** Edit classification (`:direct`, `:remove_service`, `:add_service`, `:regenerate`, `:unknown`), field mapping, message formatting
- **DB surface:** The actual `Ash.update` and `Ash.read` calls
- **Extract:** `classify_edit/1`, `format_response/2` as pure functions testable with structs

### `Haul.AI.Provisioner`
- **Pure logic:** Profile validation (`validate_profile/1`), content mapping, orchestration flow decisions
- **DB surface:** `Onboarding.run/1`, `Ash.get/read/update` on Conversation
- **Extract:** Validation + mapping logic; test orchestration with mocked deps

### Worker modules (SendBookingEmail, SendBookingSms, ProvisionCert, CheckDunningGrace)
- **Pure logic:** Email/SMS body construction, grace period comparison, polling/retry decisions
- **DB surface:** Job/Company reads, notification dispatch
- **Extract:** Body builders and comparison predicates as pure functions

## Implementation Notes

- Follow the pattern from S-028: new module or new public function in existing module, not a separate file unless the logic is substantial
- Keep the DB-coupled test as a thin integration test (1–2 tests per module verifying the wiring)
- Extracted unit tests should be `async: true` and sub-100ms each
- Don't over-abstract — if the pure function is 3 lines, inline it and test through the caller
