---
id: T-017-02
story: S-017
title: cert-provisioning
type: task
status: open
priority: medium
phase: done
depends_on: [T-017-01]
---

## Context

Automate TLS certificate provisioning for custom domains via the Fly.io API. This runs as a background job after DNS verification succeeds.

## Acceptance Criteria

- Oban worker: `Haul.Workers.ProvisionCert`
- On DNS verification success, enqueue cert provisioning job
- Job calls Fly.io API: `fly certs add <domain>` equivalent via REST API
- Poll for cert readiness (Fly provisions via Let's Encrypt — takes seconds to minutes)
- On success: update Company `domain_verified_at`, set domain status to active
- On failure: retry with exponential backoff, notify operator after 3 failures
- Domain removal: Oban worker calls `fly certs remove` equivalent
- Fly API token stored as env var (not per-operator — platform-level secret)
