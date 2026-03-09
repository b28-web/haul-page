# T-015-04 Structure: Browser QA — Self-Service Signup Flow

## Files Created

### `test/haul_web/live/app/signup_flow_test.exs`
End-to-end integration test for the complete signup flow.

```
HaulWeb.App.SignupFlowTest
├── use HaulWeb.ConnCase, async: false
├── setup: cleanup_tenants on_exit, conn_with_ip helper
│
├── describe "marketing page to signup"
│   ├── test "marketing page loads on bare domain with CTAs"
│   └── test "CTA links point to /app/signup"
│
├── describe "complete signup flow"
│   ├── test "signup → session → onboarding redirect"
│   │   (fill form, submit, POST session, verify redirect chain)
│   ├── test "onboarding wizard walkthrough"
│   │   (steps 1-6, verify content at each, go live)
│   └── test "tenant site renders after onboarding"
│       (GET / on tenant subdomain, verify operator content)
│
├── describe "signup validation"
│   ├── test "slug preview updates in real-time"
│   ├── test "validates required fields"
│   └── test "validates password requirements"
│
└── describe "mobile flow"
    └── test "signup form renders all fields"
        (viewport not testable in ExUnit, covered by Playwright)
```

## Files NOT Modified

All implementation files are complete from T-015-01, T-015-02, T-015-03. This ticket only adds tests and performs browser verification.

## Module Boundaries

- Test uses `HaulWeb.ConnCase` helpers: `create_authenticated_context/1`, `log_in_user/2`, `cleanup_tenants/0`
- Test uses `Haul.Onboarding.signup/1` to verify the full signup pipeline
- Test accesses `Haul.Accounts.Company` to verify `onboarding_complete` flag
- Test accesses `Haul.Content.SiteConfig` to verify seeded content

## Playwright MCP Verification (separate from ExUnit)

Manual browser session via Playwright MCP tools:
1. `browser_navigate` to marketing page
2. `browser_snapshot` + `browser_take_screenshot` at each step
3. `browser_click` on CTAs
4. `browser_fill_form` for signup
5. `browser_resize` for mobile viewport (375x812)
6. Screenshots saved locally (gitignored)
