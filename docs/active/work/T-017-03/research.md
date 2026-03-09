# T-017-03 Research — Browser QA for Custom Domain Flow

## Ticket Scope

Playwright MCP verification of the custom domain flow in the admin UI. End-to-end browser QA covering:
1. Navigate to `/app/settings/domain` as Pro-tier operator
2. Verify current subdomain URL displayed
3. Enter a custom domain in the form
4. Verify CNAME instructions appear with correct target
5. Click "Verify DNS" — verify status update
6. Starter-tier operator: verify upgrade prompt instead of domain form
7. Mobile: verify domain settings form is usable

## Existing Code

### Domain Settings LiveView (`lib/haul_web/live/app/domain_settings_live.ex`)

- Route: `/app/settings/domain` (authenticated, in `/app` live_session)
- Feature gate: `Billing.can?(company, :custom_domain)` — Pro+ only
- UI states:
  - No domain set → Add domain form with text input + submit
  - Pending verification → CNAME instructions table (Type/Name/Value) + "Verify DNS" button + "Remove Domain"
  - Provisioning TLS → "Setting up SSL..." spinner + Remove button
  - Active → Green badge, live domain link, Remove button (red)
  - Starter tier → Upgrade prompt with link to billing page
- Events: `validate_domain`, `save_domain`, `verify_dns`, `remove_domain`, `confirm_remove`, `cancel_remove`
- PubSub: subscribes to `domain:#{company.id}`, handles `:domain_status_changed`

### Existing Unit Tests (`test/haul_web/live/app/domain_settings_live_test.exs`)

16 tests covering: page rendering, auth redirect, subdomain display, feature gating (starter/pro/business), domain validation, normalization, pending state, CNAME instructions, remove flow (modal/confirm/cancel), active state.

### Existing QA Pattern (`test/haul_web/live/app/billing_qa_test.exs`)

Browser QA tests in this project use Phoenix LiveViewTest (not Playwright MCP browser automation). Pattern:
- `use HaulWeb.ConnCase, async: false`
- `import Phoenix.LiveViewTest`
- `setup do on_exit(fn -> cleanup_tenants() end) end`
- Helper: `authenticated_conn/2`, `set_company_plan/2`
- Assertions: `live/2`, `render_click/3`, `render_change/3`, `render_submit/3`, html string matching

### Billing Context (`lib/haul/billing.ex`)

Feature matrix: `starter: []`, `pro: [:sms_notifications, :custom_domain]`, `business/dedicated: all features`.
`Billing.can?(company, :custom_domain)` returns true for pro/business/dedicated.

### Domains Context (`lib/haul/domains.ex`)

- `normalize_domain/1` — strips protocol, path, downcases
- `valid_domain?/1` — regex validation
- `verify_dns/2` — Erlang `:inet_res.lookup/4` CNAME check (5s timeout)

### Company Model

Relevant fields: `subscription_plan` (atom, default :starter), `domain` (string, nullable), `domain_status` (atom: pending/verified/provisioning/active), `domain_verified_at` (utc_datetime).

### Test Helpers (`test/support/conn_case.ex`)

- `create_authenticated_context/1` — creates Company + tenant schema + User + token
- `log_in_user/2` — sets session with token + tenant
- `cleanup_tenants/0` — drops tenant schemas

## Key Observations

1. **Existing tests already cover unit-level LiveView interactions** — the browser QA test should focus on end-to-end user flows that chain multiple interactions
2. **DNS verification will fail in test** — `verify_dns/2` uses real `:inet_res` lookup. Tests need to either mock it or accept the error state
3. **The billing QA test pattern is the established convention** — LiveViewTest-based, not actual Playwright browser automation
4. **The test should exercise the full user journey**: tier gating → adding domain → seeing CNAME → attempting verify → removing domain
5. **Mobile responsiveness** can be tested via viewport-aware assertions or Playwright MCP screenshot
6. **Provisioning state transition** happens via PubSub — can be simulated by sending message to LiveView process
