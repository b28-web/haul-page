---
id: S-024
title: test-performance
status: open
epics: [E-013, E-001]
---

## Test Performance

Instrument, diagnose, and fix the test suite performance bottleneck. Currently 624 tests take ~170s (nearly all sync). Target: under 60s.

## Scope

- Add timing telemetry to the test suite — per-file and per-test wall-clock times
- Run telemetry, produce a report identifying the top 20 slowest tests and files
- Diagnose root causes: unnecessary `async: false`, expensive setup, tenant provisioning, compilation
- Fix the identified bottlenecks
- Establish a test timing baseline so regressions are caught early
