# T-013-06 Structure: Browser QA for Content Admin UI

## Files Changed

None. This is a QA-only ticket. No production code modifications.

## Work Artifacts Produced

```
docs/active/work/T-013-06/
├── research.md      # Codebase mapping
├── design.md        # Approach decision
├── structure.md     # This file
├── plan.md          # Step-by-step verification plan
├── progress.md      # Playwright MCP execution log
└── review.md        # Final assessment
```

## Verification Architecture

### Tool Chain

Playwright MCP (headless Chrome) → localhost:4000 → Phoenix dev server

### Browser Context

Single browser session maintaining cookies across navigations:
1. Start unauthenticated
2. Login via form submission (sets session cookie)
3. All subsequent navigations carry auth cookie
4. Resize for mobile testing

### Verification Points

| Route | What to verify | Method |
|-------|---------------|--------|
| `/app` (unauth) | Redirect to `/app/login` | browser_navigate + browser_snapshot |
| `/app/login` | Login form present | browser_snapshot |
| `/app/login` → submit | Auth + redirect to dashboard | browser_fill_form + browser_click |
| `/app` (auth) | Company name, site URL | browser_snapshot |
| `/app/content/site` | Form with fields populated | browser_snapshot |
| `/app/content/site` → save | Flash message | browser_fill_form + browser_click |
| `/` | Updated tagline on public page | browser_navigate + browser_snapshot |
| `/app/content/services` | Service list | browser_snapshot |
| `/app/content/gallery` | Gallery grid | browser_snapshot |
| `/app/content/endorsements` | Endorsement list | browser_snapshot |
| Mobile 375×812 | Hamburger menu, collapsed sidebar | browser_resize + browser_snapshot |

### ExUnit Complement

Run existing LiveView tests to confirm code-level coverage:
- `test/haul_web/live/app/site_config_live_test.exs`
- `test/haul_web/live/app/services_live_test.exs`
- `test/haul_web/live/app/gallery_live_test.exs`
- `test/haul_web/live/app/endorsements_live_test.exs`
- `test/haul_web/live/app/dashboard_live_test.exs`
- `test/haul_web/live/app/login_live_test.exs`

## Dependencies

- Dev server running on port 4000
- Default operator seeded (junk-and-handy)
- User credentials known from seed task
- Playwright MCP connected
