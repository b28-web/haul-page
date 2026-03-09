---
id: T-012-02
story: S-012
title: liveview-tenant
type: task
status: open
priority: high
phase: ready
depends_on: [T-012-01]
---

## Context

LiveView connections upgrade from HTTP to WebSocket. The tenant resolved in the Plug must carry through to the LiveView socket so all Ash operations inside LiveView use the correct tenant context.

## Acceptance Criteria

- `on_mount` hook that reads tenant from session (set by TenantResolver plug)
- Sets tenant on socket assigns (`socket.assigns.current_tenant`)
- All existing LiveViews (BookingLive, ScanLive) use the tenant context for Ash operations
- Tenant is re-verified on socket reconnect (not just trusted from initial mount)
- Tests:
  - LiveView mounted with tenant A only sees tenant A's data
  - LiveView cannot be tricked into switching tenants mid-session
