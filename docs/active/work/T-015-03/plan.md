# T-015-03 Plan: Marketing Landing Page

## Step 1: Add `is_platform_host` assign to TenantResolver

Modify `call/2` to detect when the host is the bare platform domain.

- After `resolve_company(host)`, check if `extract_subdomain(host, base_domain)` is nil AND host matches base_domain (or host is "localhost" for dev)
- Actually simpler: check in the `:fallback` branch. If we hit fallback AND the host matches base_domain, it's the platform host.
- Add `assign(:is_platform_host, true/false)` to all paths

**Verify:** Existing tests still pass (`mix test test/haul_web/controllers/page_controller_test.exs`)

## Step 2: Add controller dispatch logic

Modify `home/2` in PageController:
```elixir
def home(conn, params) do
  if conn.assigns[:is_platform_host] do
    marketing(conn, params)
  else
    # existing operator logic
  end
end
```

Extract existing operator logic into `operator_home/2` private function.
Add `marketing/2` private function that renders `:marketing` template.

**Verify:** Existing tests may need adjustment since dev base_domain=localhost will now show marketing page.

## Step 3: Create marketing template

Create `lib/haul_web/controllers/page_html/marketing.html.heex` with all sections:
- Nav, Hero, Features, How It Works, Pricing, Demo, Footer
- Use existing design tokens and Heroicons
- Mobile-responsive with Tailwind

## Step 4: Fix existing tests

Existing page_controller_test.exs tests expect operator content on `/`. Since `localhost` is now the platform host, these tests will get the marketing page instead.

Fix: Set the conn host to a subdomain (e.g., `joes.localhost`) so TenantResolver resolves the operator tenant, OR set `is_platform_host` to false in setup.

## Step 5: Write marketing page tests

New test file: `test/haul_web/controllers/marketing_page_test.exs`
- GET / returns marketing page content (hero heading, pricing, features)
- CTA links to /app/signup
- Does not contain operator-specific content
- No tenant setup needed (bare domain = platform host)

## Step 6: Run full test suite

`mix test` — ensure no regressions.

## Testing strategy
- Unit: TenantResolver.extract_subdomain/2 already has doctests
- Integration: ConnCase tests for both marketing and operator pages
- No browser QA in this ticket (T-015-04 handles that)
