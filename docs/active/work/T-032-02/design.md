# T-032-02 Design: Supervision Tree Review

## Decision

**No structural changes to the supervision tree.** The flat `:one_for_one` tree is the correct design for this application's current (and foreseeable) needs. Document the rationale and define when to revisit.

## Options Evaluated

### Option A: Add intermediate supervisors (3 groups)

Group children into Core, Background, and Init supervisors.

**Pros:**
- Separate `max_restarts` budgets per group (init task crashes don't count against core infrastructure)
- Clearer visual organization in observer/remote_console

**Cons:**
- Adds 3 new modules with zero behavioral change (all groups would use :one_for_one)
- More indirection when debugging — "which supervisor owns this process?"
- Premature — the ticket itself says "don't add complexity preemptively"
- 9 children is well within the comfort zone for a flat tree

**Verdict:** Rejected. Adds complexity with no fault isolation benefit.

### Option B: Group only init tasks under a separate supervisor

Put the two :transient tasks under their own supervisor to isolate their restart budget.

**Pros:**
- Init task crashes (during startup retries) don't eat into the main supervisor's restart budget

**Cons:**
- Init tasks are :transient — they exit normally after ~100ms. In normal operation they're not even running.
- The failure window is tiny (startup only) and retries are bounded by :transient semantics
- Adds a module for an edge case that hasn't manifested

**Verdict:** Rejected. Solves a theoretical problem.

### Option C: No change — document and define revisit criteria ✓

Keep the flat tree. Add a code comment documenting the decision and when to revisit. Write the analysis in work artifacts.

**Pros:**
- Zero code churn
- Decision is documented for future reference
- Revisit criteria are clear and actionable

**Cons:**
- None. This is the right call for a 9-child flat tree with no coupled processes.

**Verdict:** Selected.

## Revisit Criteria

Add intermediate supervisors when ANY of these become true:
1. **15+ children** in the supervision tree (organizational complexity)
2. **Coupled processes** that need `:one_for_all` or `:rest_for_one` (e.g., a registry + dynamic supervisor pair)
3. **Stateful GenServers** whose crash budget needs isolation from core infrastructure (e.g., a connection pool to an external service that may flap)
4. **Different restart strategies needed** for different groups

## Implementation

The "implementation" for this ticket is documentation:
1. Add a brief comment in `application.ex` explaining the flat tree decision
2. Write the work artifacts (research, design, review) as the permanent record
3. Run full test suite to confirm nothing is broken (no code changes = no risk, but verify anyway)
