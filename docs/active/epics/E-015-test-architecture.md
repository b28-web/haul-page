---
id: E-015
title: test-architecture
status: active
---

## Test Architecture

80% of test files (76/95) hit the real database. Only 22 files are true unit tests. The test pyramid is flat — almost everything runs at the integration level because Ash makes it easy to test through the DB and there's no factory/fixture layer to reduce boilerplate.

This creates compounding problems:
- Every test file hand-rolls 15+ lines of company → tenant schema → user → token setup
- `CREATE SCHEMA` DDL can't be rolled back by Ecto sandbox, forcing `async: false` on everything
- No separation between "tests Ash action logic" and "tests LiveView rendering"
- Pure domain logic buried inside Ash actions and LiveView handlers is untestable without full stack setup

### Goals

- Establish a 3-tier test model with documented conventions:
  - **Unit** (`ExUnit.Case, async: true`): pure logic, no DB, no HTTP
  - **Resource** (`DataCase`): Ash actions, policies, relationships — real DB, no HTTP
  - **Integration** (`ConnCase`): LiveView rendering, controller responses — real DB + HTTP
- Centralized test factories/fixtures — one place to create tenants, users, services, etc.
- Extract testable pure functions from LiveViews and Ash resource modules
- Push tests down the pyramid: new code defaults to unit tests, integration tests only for user flows
- Full suite stays green as a gate (`mix test` before merge to main)

### Relationship to E-014

E-014 (dev resource efficiency) attacks the symptom: slow tests due to per-test schema provisioning. E-015 attacks the cause: too many tests require schema provisioning because there's no unit test layer for domain logic.

S-025 (setup_all migration) and S-025's shared tenant fixture remain valid — they make the integration tests faster. E-015 is about having fewer integration tests in the first place.

### Non-goals

- Mocking Ash's data layer wholesale — Ash is designed to test through the framework
- Removing all DB tests — resource-level tests that verify policies, constraints, and multi-tenancy need the real DB
- Rewriting existing passing tests — only refactor when a test file is touched for other reasons, or when writing new features
