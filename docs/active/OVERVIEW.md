# Project Overview — Active Status Board

> **All agents: update this file when you complete a ticket, surface a blocker, or learn something that affects other work.** This is the central information board. The developer reads this to understand what's happening without checking every ticket.

## Current state

**Phase:** Foundation (S-001) in progress. No Phoenix app yet — T-001-01 (scaffold) is being implemented.

**What works:** Nothing runs yet. Repo has specs, tickets, CI config, justfiles, docs.

**What's next:** Once scaffold lands, wave 1 unlocks version-pinning + tailwind-setup in parallel.

## Active tickets

| Ticket | Title | Phase | Agent notes |
|--------|-------|-------|-------------|
| T-001-01 | scaffold-phoenix | implement | — |

## Recently completed

_None yet._

## Blockers & risks

_None identified._

## Decisions made during implementation

Log decisions here that aren't in the spec but affect other tickets. Other agents need to see these.

_None yet._

## Cross-ticket notes

Things an agent learned that another agent working a different ticket should know.

_None yet._

---

## Quick reference

**DAG:** 29 tickets, 9 waves, critical path 9. Max 2 concurrent.

**Chains:**
```
Infra:    T-001-01 → 02 → 03 → 04 → 05 → 06
Surface:  T-001-01 → T-002-03 → T-002-01 → T-002-02 → T-005-01 → 02 → 03
Tenancy:  T-002-03 → T-004-01 → T-003-01 → T-003-02 → T-003-03
Content:  T-004-01 → T-006-01 → 02 → 03 → 04
Notify:   T-001-06 → T-007-01,02 → 03 → 04
Payments: T-001-06 → T-008-01 → 02, 03
Address:  T-001-06 → T-009-01 → 02
```

**Epics (ongoing health):**
- E-001 Dev environment — clone-to-running in 5 min
- E-002 Deploy pipeline — every push to main deploys
- E-003 Public surface — fast, accessible, print-ready
- E-004 Domain model — Ash resources stay correct
- E-005 Content system — schema-driven, seed-reproducible
- E-006 First customer — can we hand this to a hauler this week?
- E-007 Demo instance — live URL that sells the product
- E-008 Data security — tenant isolation tested from day one
