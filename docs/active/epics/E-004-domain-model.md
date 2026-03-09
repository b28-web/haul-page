---
id: E-004
title: domain-model
status: pending
---

## Domain Model Integrity

The Ash resource definitions are the source of truth for the business. They must stay correct, consistent, and well-tested as features are added.

## Ongoing concerns

- Ash resources compile without warnings
- State machine transitions are tested for every valid and invalid path
- Policies enforce role-based access — no action runs without an explicit permit
- Migrations are generated and match the resource definitions
- AshPaperTrail captures all mutations for audit
- Money values use AshMoney — no raw integer arithmetic in application code
- Cross-domain access goes through defined interfaces, not direct resource calls
