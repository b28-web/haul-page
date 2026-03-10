---
id: T-030-02
story: S-030
title: fix-defensive-rescues
type: task
status: open
priority: medium
phase: done
depends_on: [T-030-01]
---

## Context

T-030-01 audit identifies try/rescue blocks that should be removed or narrowed. This ticket implements those changes.

## Acceptance Criteria

- Remove or narrow every rescue site classified as "remove" or "narrow" by the audit
- Known targets (confirm against audit):
  1. `CostTracker.record_call/1` — remove rescue, let Ash.create crash propagate
  2. `Onboarding.seed_content/1` — use non-bang seed or let bang crash
  3. `Anthropic.stream_message/2` — rescue only network-specific exceptions (Req.Error, Mint.TransportError)
  4. `Domains.verify_dns/2` — rescue specific DNS exceptions, preserve error context
  5. `ProvisionCert.send_failure_notification/2` — remove rescue, let Swoosh errors propagate
  6. `Prompt.prompts_dir/0` — use `Application.compile_env` instead of runtime rescue
- Update tests that assert on the old error-swallowing behavior
- All 845+ tests pass
- No new broad rescue blocks introduced

## Implementation Notes

- For each change: read the calling code first to understand what it expects
- Some callers may need adjustment if they pattern-match on `{:error, :recording_failed}` etc.
- The Anthropic chat rescue is in a spawned Task — use `Task.async` with proper linking instead of manual spawn + rescue if appropriate
