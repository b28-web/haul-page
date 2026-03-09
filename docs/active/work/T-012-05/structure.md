# T-012-05 Structure: Browser QA for Tenant Routing

## Overview

This is a QA-only ticket. No production code changes. The deliverable is verification of existing tenant routing via Playwright MCP browser testing and ExUnit test confirmation.

## Files Created

None. This ticket produces only work artifacts (progress.md, review.md).

## Files Modified

None. No code changes.

## Files Read/Verified

| File | Purpose |
|------|---------|
| `lib/haul_web/plugs/tenant_resolver.ex` | Understand resolution logic |
| `lib/haul_web/live/tenant_hook.ex` | Understand LiveView tenant context |
| `lib/haul_web/router.ex` | Confirm tenant plug in pipeline |
| `config/config.exs` | base_domain setting |
| `test/haul_web/plugs/tenant_resolver_test.exs` | Existing plug tests |
| `test/haul_web/live/tenant_hook_test.exs` | Existing hook tests |
| `test/haul/tenant_isolation_test.exs` | Existing isolation tests |

## Work Artifacts

| File | Content |
|------|---------|
| `docs/active/work/T-012-05/research.md` | Codebase mapping |
| `docs/active/work/T-012-05/design.md` | Approach decision |
| `docs/active/work/T-012-05/structure.md` | This file |
| `docs/active/work/T-012-05/plan.md` | Step-by-step QA plan |
| `docs/active/work/T-012-05/progress.md` | QA results per step |
| `docs/active/work/T-012-05/review.md` | Summary and assessment |

## Testing Strategy

### Browser QA (Playwright MCP)

Prerequisite: Dev server running on `localhost:4000` with tenant provisioned and content seeded.

Steps executed via Playwright MCP tools:
1. `browser_navigate` to each route
2. `browser_snapshot` to capture rendered DOM
3. `browser_resize` for mobile viewport
4. `browser_console_messages` for error check

### ExUnit Verification

Run existing test suite to confirm tenant routing tests pass. No new tests created — existing coverage is comprehensive (plug tests, hook tests, isolation tests).

## Dependencies

- Dev server must be running (`mix phx.server`)
- Default operator tenant must be provisioned with content seeded
- Playwright MCP must be connected (configured in `.mcp.json`)
