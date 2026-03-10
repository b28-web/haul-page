---
id: T-033-03
story: S-033
title: mock-service-layer
type: task
status: open
priority: high
phase: done
depends_on: [T-033-01]
---

## Context

After T-033-02 extracts pure logic, some tests will still need to verify orchestration — "does the module call the right services in the right order?" — without actually hitting the DB. This ticket introduces mocks for **external service boundaries only** — not for Ash resource operations.

### Ecosystem guidance: mock boundaries, not Ash

Web research and Ash community patterns are clear: **don't mock Ash resource calls**. Ash actions hit the database through the resource DSL — mocking at that level fights the framework and produces tests that pass while production breaks. The idiomatic Elixir approach is:

- **Real DB for Ash actions** — use Ecto sandbox, test actual constraints/policies
- **Mocks only at system edges** — AI/LLM calls, SMS, email, Stripe, Google Places, DNS/cert APIs
- **The existing adapter pattern is the right foundation** — `ChatSandbox`, compile-time adapters via `Application.compile_env` (7 modules already converted in S-031)

Do NOT introduce `Haul.MockRepo` or per-domain Ash mocks.

## Acceptance Criteria

- Extend the existing adapter/sandbox pattern to cover all external service boundaries
- Audit which external calls are already mocked vs. hit real (or no-op) services in tests
- Ensure every external service has a test adapter that's fast and deterministic:
  - AI/LLM: `ChatSandbox` (exists)
  - SMS: test adapter (exists via compile_env)
  - Email: Swoosh test adapter (exists)
  - Stripe: test adapter (exists via compile_env)
  - Google Places: test adapter (exists via compile_env)
  - DNS/cert provisioning: test adapter (exists via compile_env)
- If any external call lacks a test mock, add one
- Convert orchestration tests (Provisioner, EditApplier) to use injected test adapters instead of DB round-trips for the external calls they coordinate
- Document the mocking conventions in `docs/knowledge/test-architecture.md`: "mock the boundary, not Ash"
- All tests pass

## Implementation Notes

- The codebase already uses `ChatSandbox` for AI mocking and compile-time adapters (`Application.compile_env`) for service switching — extend these patterns, do not introduce Mox or a new dependency
- Mox is the Elixir-community standard but requires defining behaviours for every mockable module. The existing adapter pattern is simpler and already covers 7 modules — prefer consistency
- Don't mock Ash validation, reads, or writes — constraint checks and policy enforcement should hit the real DB
- Whatever approach is chosen, it must work with `async: true` (process-isolated, no global state)

## Risks

- Over-mocking can make tests pass while production breaks. Keep at least one integration test per module that exercises the real DB path
- If `ChatSandbox` uses process dictionary or global ETS, verify it's safe for concurrent test execution (caller-key pattern like Mox)
