---
id: T-020-02
story: S-020
title: auto-provision-pipeline
type: task
status: open
priority: high
phase: done
depends_on: [T-020-01, T-014-01, T-019-02]
---

## Context

Wire the full pipeline: conversation extraction → content generation → tenant provisioning → live site. The operator goes from chat to working website in a single session.

## Acceptance Criteria

- `Haul.AI.Provisioner.from_profile/1` orchestrates:
  1. Validate extracted OperatorProfile (all required fields present)
  2. Generate content (service descriptions, tagline, why-hire-us, meta description)
  3. Create Company (tenant) with slug from business name
  4. Provision tenant schema + run migrations
  5. Create owner User with magic link
  6. Seed content from generated + extracted data
  7. Return `{:ok, %{company: company, site_url: url, login_link: link}}`
- Pipeline runs as an Oban job (resilient to failures, retryable)
- Each step is idempotent (safe to retry on partial failure)
- Estimated wall time: <30 seconds for the full pipeline
- On success: chat UI shows "Your site is live!" with link to site and admin login
- On failure: chat UI shows "Something went wrong — we'll email you when it's ready"
- Token usage and cost tracked per provisioning run
