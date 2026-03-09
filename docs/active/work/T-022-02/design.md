# T-022-02 Design: Proxy Link Helpers

## Problem

When viewing tenant pages under `/proxy/:slug/...`, internal links like `href="/book"` drop the user out of the proxy namespace back to hostname-resolved routes (which don't work on localhost).

## Options

### Option A: Helper module with `tenant_path/2`

A simple module `HaulWeb.ProxyHelpers` with a single function:

```elixir
def tenant_path(assigns_or_conn, path)
  # When proxy_slug is set: "/proxy/#{proxy_slug}#{path}"
  # When proxy_slug is nil/absent: path unchanged
```

Templates use `ProxyHelpers.tenant_path(assigns, "/book")` instead of hardcoded `"/book"`.

**Pros:** Explicit, easy to understand, no magic. Works for both conn and socket assigns.
**Cons:** Slightly verbose call site. Templates need to import or alias the module.

### Option B: Function component wrapper

A `<.tenant_link>` component that wraps `<a>` with proxy-aware href.

**Pros:** HEEx-native feel, familiar to Phoenix developers.
**Cons:** Overkill for 5 links. Adds a component that competes with `<.link>`. Doesn't help with Elixir-side redirects.

**Rejected:** More complexity than needed for 5 call sites.

### Option C: Plug-level path rewriting

Intercept outgoing HTML and rewrite paths. Essentially a response filter.

**Rejected:** Fragile, terrible for debugging, doesn't handle LiveView event redirects.

### Option D: Assign-based helper imported into views

Same as Option A but `import`ed via the `:live_view` and `:html` quotes in `haul_web.ex`, so it's available everywhere without explicit import.

**Pros:** Same as A, but no explicit import needed in each file.
**Cons:** Pollutes namespace slightly, but the function name `tenant_path` is clear.

## Decision: Option A with import via `haul_web.ex` (hybrid A+D)

Create `HaulWeb.ProxyHelpers` with `tenant_path/2`. Import it into the `:live_view` and `:html` using blocks in `haul_web.ex` so it's available in all templates and LiveViews without explicit imports.

### API

```elixir
# In templates (assigns available as @):
href={tenant_path(assigns, "/book")}
href={tenant_path(assigns, ~p"/pay/#{@job.id}")}
href={tenant_path(assigns, "/")}

# In LiveView event handlers (socket available):
redirect(socket, to: tenant_path(socket.assigns, "/book"))
```

### Implementation details

- `tenant_path/2` accepts either a map with `:proxy_slug` key or a `%Plug.Conn{}` struct
- When `proxy_slug` is nil or absent → returns path unchanged
- When `proxy_slug` is set → prepends `/proxy/#{proxy_slug}`
- Path must start with `/` (validation)

### QR code handling

QR controller stays unchanged. Per the AC: "QR codes are for print" — they should encode the real tenant URL, not the proxy URL. The current `HaulWeb.Endpoint.url() <> "/scan"` is correct.

### Links that do NOT need proxy-rewriting

- Admin links (`/app/*`) — different route scope, not under proxy
- Phone/email links — external protocols
- ChatLive redirects to `/app/signup` — admin flow
- QR code URLs — should be real URLs for print

### Links that DO need proxy-rewriting

| File | Line(s) | Current | New |
|------|---------|---------|-----|
| ScanLive | 51, 157 | `href="/book"` | `href={tenant_path(assigns, "/book")}` |
| PaymentLive | 146 | `href="/"` | `href={tenant_path(assigns, "/")}` |
| PaymentLive | 175, 276 | `href={~p"/pay/#{@job.id}"}` | `href={tenant_path(assigns, ~p"/pay/#{@job.id}")}` |
