---
id: T-032-02
story: S-032
title: supervision-tree-review
type: task
status: open
priority: low
phase: done
depends_on: [T-032-01]
---

## Context

The supervision tree is flat — all children at one level under Application with `:one_for_one` strategy. This is fine for the current app size, but as the app grows, intermediate supervisors improve fault isolation. After T-032-01 moves init tasks into the tree, review whether further structure is warranted.

## Acceptance Criteria

- Review the supervision tree and document the current structure in `docs/active/work/T-032-02/`
- Evaluate whether intermediate supervisors would improve fault isolation:
  - **Core group** (Repo, PubSub, Endpoint) — must stay up
  - **Background group** (Oban, RateLimiter, DNSCluster) — can restart independently
  - **Init group** (ContentLoader, AdminBootstrap) — run-once tasks
- If grouping improves isolation: implement with `Supervisor` children
- If not warranted yet: document the decision and when to revisit (e.g., "add intermediate supervisors when we have 3+ background workers or stateful GenServers")
- App starts and all tests pass regardless of decision

## Implementation Notes

- With `:one_for_one`, each child restarts independently — the current flat tree is actually fine for fault isolation
- Intermediate supervisors add value when you want `:one_for_all` or `:rest_for_one` for a group of related children
- Don't add complexity preemptively — this ticket may conclude "no change needed, here's why"
- Consider whether Oban's internal supervision is sufficient for background job fault isolation (it likely is)
