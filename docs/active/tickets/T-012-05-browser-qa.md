---
id: T-012-05
story: S-012
title: browser-qa
type: task
status: open
priority: high
phase: ready
depends_on: [T-012-02, T-012-03]
---

## Context

Playwright MCP verification of multi-tenant routing. Confirm that subdomain-based and custom-domain-based tenant resolution serves the correct operator's content.

## Test Plan

1. Navigate to `http://localhost:4000/` (bare domain) — should serve default/demo tenant
2. Navigate with Host header set to a known tenant subdomain — verify correct business name, phone, services render
3. Navigate with Host header set to a different tenant — verify different content
4. Resize to mobile (375x812) — confirm tenant-specific content still renders correctly
5. Navigate to `/book` and `/scan` under each tenant — verify LiveView connects with correct tenant context
6. Attempt cross-tenant URL manipulation — confirm isolation holds

## Acceptance Criteria

- All tenant routing scenarios verified via Playwright MCP snapshots
- No cross-tenant data leakage observed
- Failures documented with snapshot output
