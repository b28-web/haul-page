---
id: E-014
title: dev-resource-efficiency
status: active
---

## Dev Resource Efficiency

The production app runs on a 256MB Fly VM. The dev environment consumes 5.5GB — a 20x ratio caused entirely by Docker Desktop running a single Postgres container. The test suite takes ~90s for 845 tests when the T-024 analysis showed a clear path to under 45s.

### Goals

- Dev environment total RAM under 500MB (BEAM + Postgres + watchers)
- Test suite under 45 seconds for the full 845+ test suite
- No Docker Desktop dependency for local development
- Reproducible toolchain versions via `.mise.toml`

### Context

The BEAM app itself is lean (~270MB dev, 32MB at rest). Docker Desktop's krun VM on Apple Silicon is a fixed 4.7GB floor cost regardless of container workload. The host machine already has Postgres 18 installed natively — Docker is running an older Postgres 16 inside a 5.8GB Linux VM.

Test suite was reduced from 173s → 78s by S-024. The remaining gap is structural: 54 `create_authenticated_context` calls provisioning Postgres schemas per-test instead of per-file, zero `setup_all` usage.
