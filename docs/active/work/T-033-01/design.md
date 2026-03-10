# T-033-01 Design: Audit Mock Candidates

## Decision: Classification Criteria

### Three categories per the ticket AC

1. **DB-required** — Tests that exercise:
   - Unique constraints enforced at DB level (slug, email)
   - Tenant schema isolation (cross-schema queries)
   - Ash policy enforcement (actor-based authorization)
   - Multi-resource transactions (Onboarding.run, Provisioner.from_profile)
   - Foreign key constraints (versions, company_id)
   - Query behavior (ordering, filtering, aggregation)

2. **Mock-feasible** — Tests where:
   - Inputs are deterministic (fixed structs, maps, strings)
   - The function under test does computation/transformation, not persistence
   - DB is used only for setup (creating test data) not for verification
   - Side effects are already mocked (ChatSandbox, Swoosh, process mailbox)
   - Ash validations could be tested via changeset inspection (but see note below)

3. **Render-only** — LiveView/controller tests where:
   - Only assertion is `assert html =~ "..."` or element presence
   - No post-action DB reads (no `Ash.read!` after a form submit)
   - State changes are UI-only (step navigation, panel toggle, input enable/disable)

### Important constraint: Ash validation tests

The ticket says "Don't classify Ash validation tests as mock-feasible — Ash constraints run through the DB layer and that's intentional." This affects content resource tests (service, endorsement, gallery_item, page, site_config) where `requires X` tests look like pure validation but actually exercise Ash's create action pipeline which touches the DB. These stay DB-required even though they look mockable.

However, **non-Ash validation** (e.g., `Onboarding.run/1` param validation that returns `{:error, ...}` before touching Ash) IS mock-feasible.

## Approach: Module-Level vs Test-Level Classification

**Decision: Classify at test level, flag at module level.**

Rationale: The ticket asks for per-test classification but the actionable output for T-033-02..05 is at the module level:
- T-033-02 needs to know which modules have extractable pure logic
- T-033-03 needs to know which modules benefit from service-layer mocks
- T-033-04 needs the QA overlap list
- T-033-05 needs to know which files can flip to async:true

So the audit will classify every test, then roll up to module-level recommendations.

## Time Savings Estimation

**Method:** Use per-file trace timings. Estimate savings as:
- Full module → ExUnit.Case: save ~100% of current time (setup eliminated)
- Split out pure tests: save proportional to mock-feasible test count × avg test time
- QA dedup: save 100% of removed test time
- Async unlock: no direct per-test savings, but wall-clock reduction from parallelism

**Conservative estimate:** Don't assume all mock-feasible tests will actually be converted. Flag the opportunity; T-033-02..04 will decide what's worth converting.

## What Was Rejected

1. **Automated classification via AST analysis** — Considered parsing test files for `Ash.read!`, `Ash.create!` etc. Rejected: too many false positives (setup code vs assertion code), and the nuance of "Ash validations stay DB" can't be captured by grep.

2. **Classify by setup block only** — If setup uses `create_authenticated_context`, mark entire module as DB-required. Rejected: many modules have heavy setup but individual tests only assert on HTML.

3. **Skip render-only category** — Just do DB-required vs mock-feasible. Rejected: render-only is the highest-value category for ConnCase tests; it identifies tests that could potentially run without any DB setup if the LiveView mount were mocked.
