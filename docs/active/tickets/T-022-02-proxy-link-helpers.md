---
id: T-022-02
story: S-022
title: proxy-link-helpers
type: task
status: open
priority: medium
phase: ready
depends_on: [T-022-01]
---

## Context

When viewing tenant pages under `/proxy/:slug/...`, internal links (e.g., "Book Now" → `/book`, nav links to `/scan`) need to stay within the proxy namespace. Without this, clicking a link drops you out of the proxy back to the hostname-resolved route (which doesn't work on localhost).

## Acceptance Criteria

- Helper function `HaulWeb.ProxyHelpers.tenant_path(assigns_or_conn, path)`:
  - When `proxy_slug` is set: returns `"/proxy/#{proxy_slug}#{path}"`
  - When `proxy_slug` is nil: returns `path` unchanged
- All tenant-facing templates use the helper for internal links (home, scan, book, pay, chat)
- LiveView `handle_event` redirects (e.g., after booking submission) use proxy-aware paths
- The QR code generation at `/proxy/:slug/scan/qr` encodes the correct URL (the real tenant URL, not the proxy URL — QR codes are for print)
- Tests: verify links within proxied pages point to `/proxy/:slug/...` paths
