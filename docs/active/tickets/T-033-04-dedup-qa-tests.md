---
id: T-033-04
story: S-033
title: dedup-qa-tests
type: task
status: open
priority: medium
phase: done
depends_on: [T-033-01]
---

## Context

The codebase has 7 `*_qa_test.exs` files (110 tests, 22.4s) that were created as "browser QA" during development. But they all use `Phoenix.LiveViewTest` — the same test framework as the regular LiveView tests. They're not real browser/Playwright tests. They run at the same tier as the non-QA tests and often test overlapping flows.

This ticket deduplicates or merges them to eliminate redundant coverage.

## QA files and their counterparts

| QA file | Time | Tests | Non-QA counterpart | Overlap? |
|---------|------|-------|--------------------|----------|
| `chat_qa_test.exs` | 4.0s | 25 | `chat_live_test.exs` (2.7s, 22) | High — both test chat send/receive, streaming, errors |
| `provision_qa_test.exs` | 4.8s | 14 | `preview_edit_test.exs` (5.6s, 13) | High — both test provision→preview→edit→go-live |
| `onboarding_qa_test.exs` | 1.9s | 10 | `onboarding_live_test.exs` (2.8s, 14) | Moderate — QA tests the wizard flow, non-QA tests individual steps |
| `billing_qa_test.exs` | 2.5s | 16 | `billing_live_test.exs` (2.2s, 14) | High — both test upgrade/portal/status flows |
| `domain_qa_test.exs` | 2.2s | 14 | `domain_settings_live_test.exs` (2.6s, 16) | High — both test domain add/verify/remove |
| `proxy_qa_test.exs` | 2.5s | 13 | `proxy_routes_test.exs` + `proxy_tenant_resolver_test.exs` | Moderate |
| `superadmin_qa_test.exs` | 3.8s | 18 | `accounts_live_test.exs` + `impersonation_test.exs` + `security_test.exs` | High |

**Total QA: 22.4s, 110 tests**

## Acceptance Criteria

- For each QA file, compare test-by-test against its non-QA counterpart(s)
- For each test in a QA file, classify as:
  - **Duplicate** — same assertion exists in non-QA test → delete from QA
  - **Unique flow test** — tests a multi-step flow not covered elsewhere → merge into non-QA file
  - **Unique edge case** — tests an edge case not covered elsewhere → merge into non-QA file
- After dedup:
  - Delete QA files that are 100% duplicates
  - Merge unique tests from partially-duplicate QA files into the non-QA counterpart
  - Remaining QA tests (if any) should be renamed to drop the `_qa` suffix or merged
- QA test count reduced by ≥50% (from 110 to ≤55)
- No coverage loss — every unique assertion from QA files exists somewhere
- All tests pass
- `mix haul.test_pyramid` shows improved ratios

## Implementation Notes

- Work file-by-file, starting with the highest-overlap pairs (chat, billing, domain)
- Use `mix test <file> --trace` to compare specific test names between QA and non-QA
- When merging, prefer adding the unique test into the existing non-QA `describe` block rather than creating new sections
- If a QA test does something the non-QA doesn't (e.g., tests a 5-step flow end-to-end), that's valuable — keep it but move it to the non-QA file
- Don't merge if it would make the non-QA file unwieldy (>30 tests). In that case, keep as separate file but rename
