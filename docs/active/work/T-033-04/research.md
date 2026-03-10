# T-033-04 Research: Dedup QA Tests

## QA Files Inventory (7 files, 110 tests)

| QA File | Tests | Non-QA Counterpart(s) | Counterpart Tests |
|---------|-------|-----------------------|-------------------|
| chat_qa_test.exs | 25 | chat_live_test.exs | 21 |
| provision_qa_test.exs | 14 | preview_edit_test.exs | 13 |
| onboarding_qa_test.exs | 10 | onboarding_live_test.exs | 14 |
| billing_qa_test.exs | 16 | billing_live_test.exs | 15 |
| domain_qa_test.exs | 14 | domain_settings_live_test.exs | 17 |
| proxy_qa_test.exs | 13 | proxy_routes_test.exs (7) + proxy_tenant_resolver_test.exs (5) | 12 |
| superadmin_qa_test.exs | 18 | accounts_live_test.exs (10) + impersonation_test.exs (16) + security_test.exs (11) | 37 |

## Test-by-Test Overlap Analysis

### 1. chat_qa_test.exs (25 tests) vs chat_live_test.exs (21 tests)

**DUPLICATE (14 tests):**
- "renders header with title and manual signup link" ≈ mount/"renders chat page" + fallback/"renders manual signup link"
- "shows welcome message" ≈ mount/"starts with empty message list"
- "renders input field with placeholder and Send" ≈ mount/"renders chat page"
- "renders 'Prefer a form?' fallback link" ≈ fallback/"renders form fallback link"
- "profile sidebar shows empty state" ≈ mount/"renders profile sidebar with empty state"
- "input is disabled during streaming" ≈ streaming/"disables input during streaming"
- "input re-enables after streaming" ≈ streaming/"re-enables input after streaming"
- "populates all fields after extraction" ≈ live_extraction/"profile panel updates"
- "services list renders" ≈ live_extraction/"services list renders"
- "differentiators list renders" ≈ live_extraction/"differentiators render"
- "progress bar width reflects completeness" ≈ live_extraction/"completeness indicator updates"
- "shows profile complete CTA" ≈ live_extraction/"profile complete CTA appears"
- "redirects when chat not configured" ≈ llm_not_configured/"redirects to /app/signup"
- "first message AI error redirects" ≈ first_message_error/"redirects to /app/signup with flash"

**UNIQUE (11 tests):**
- "multi-turn conversation builds profile progressively" — end-to-end multi-turn, not in non-QA
- "user messages are right-aligned, AI left-aligned" — CSS layout check, not in non-QA
- "typing indicator has animated dots" — animation class check, not in non-QA
- "toggle button not visible before profile" — mobile toggle, not in non-QA
- "toggle button appears after extraction and toggles" — mobile toggle interaction
- "Build my site triggers provisioning state" — provisioning from chat, not in non-QA
- "provisioning_complete shows site URL" — provisioning result display
- "provisioning_failed shows error and retry" — provisioning error handling
- "conversation is found when reconnecting" — session persistence
- "later message AI error stays on page" ≈ first_message_error/"stays on page" — DUPLICATE (missed above)
- "shows message limit error at max messages" ≈ rate_limiting/"enforces max" — DUPLICATE

**Revised: 16 DUPLICATE, 9 UNIQUE**

### 2. provision_qa_test.exs (14 tests) vs preview_edit_test.exs (13 tests)

**DUPLICATE (5 tests):**
- "provisioning enters edit mode with preview panel" ≈ edit_mode/"shows preview panel"
- "tagline edit updates SiteConfig" ≈ regeneration/"regenerates tagline" (partial)
- "phone edit updates SiteConfig" ≈ direct_edits/"updates phone number"
- "multiple edits increment counter" ≈ direct_edits/"increments edit count"
- "go live finalizes session" ≈ go_live/"finalizes session"

**UNIQUE (9 tests):**
- "chat UI renders and accepts messages before provisioning" — pre-provision chat verify
- "shows building message during provisioning" — provisioning state transition
- "provisioning_complete message shows edit instructions" — edit instructions shown
- "service addition creates service in tenant" — service add with DB verify
- "tenant landing page renders with provisioned content" — cross-page tenant verify
- "tenant scan page renders after provisioning" — cross-page tenant verify
- "tenant booking form renders after provisioning" — cross-page tenant verify
- "edited content appears on tenant landing page" — edit persistence to landing
- "mobile preview toggle shows/hides preview panel" — mobile toggle in edit mode

### 3. onboarding_qa_test.exs (10 tests) vs onboarding_live_test.exs (14 tests)

**DUPLICATE (4 tests):**
- "renders with onboarded operator content" — partially overlaps step 1/"shows pre-filled site config"
- "login page renders" — overlaps authentication/"renders for authenticated users" (indirect)
- "owner user exists with correct role" — data verification, not UI test
- "site config updated with operator info" — data verification, not UI test

**UNIQUE (6 tests):**
- "displays default services from content pack" — content pack quality verify
- "renders gallery and endorsements" — scan page after onboarding
- "displays gallery items with captions" — gallery detail verify
- "displays endorsement quotes" — endorsement content verify
- "renders booking form" — booking page after onboarding
- "default content is professional, not placeholder" — content quality assertion

### 4. billing_qa_test.exs (16 tests) vs billing_live_test.exs (15 tests)

**DUPLICATE (11 tests):**
- "renders all four tier cards" ≈ "renders billing page with plan cards"
- "displays Starter as current plan" ≈ "shows current plan as highlighted" + "shows correct pricing"
- "shows upgrade buttons for Pro/Business/Dedicated" ≈ "shows correct buttons"
- "shows feature labels on plan cards" ≈ "shows feature labels"
- "no Manage Payment Methods without Stripe" ≈ manage_billing/"not shown without stripe customer"
- "clicking Upgrade to Pro creates customer" ≈ upgrade/"triggers checkout"
- "returning with session_id shows success" ≈ checkout_return/"shows success flash"
- "billing reflects Pro after upgrade" ≈ upgrade/"shows correct buttons for pro plan user"
- "upgrading existing subscription updates plan" ≈ upgrade/"updates plan"
- "clicking downgrade shows confirmation" ≈ downgrade/"shows confirmation modal"
- "confirming downgrade changes plan" ≈ downgrade/"confirming downgrade changes plan"

**UNIQUE (5 tests):**
- "Starter plan: domain settings shows upgrade prompt" — cross-page feature gate
- "Pro plan: domain settings shows custom domain form" — cross-page feature gate
- "after downgrade, domain settings shows upgrade prompt" — cross-page state change
- "dunning alert shows payment issue warning" — dunning state not tested in non-QA
- "unauthenticated user redirected to login" ≈ auth/"redirects" — DUPLICATE

**Revised: 12 DUPLICATE, 4 UNIQUE**

### 5. domain_qa_test.exs (14 tests) vs domain_settings_live_test.exs (17 tests)

**DUPLICATE (12 tests):**
- "shows upgrade prompt" ≈ feature_gating/"shows upgrade prompt for starter"
- "upgrade prompt links to billing" ≈ feature_gating/"shows upgrade prompt"
- "shows current subdomain address" ≈ domain_settings/"shows subdomain address"
- "full flow: add→CNAME→verify→remove" ≈ add_domain/"saves valid domain" + pending/"shows CNAME" + remove/"removes domain"
- "pending state: shows CNAME" ≈ pending/"shows CNAME instructions"
- "provisioning state: shows SSL" — tested via DB state preset, partially unique
- "active state: shows green badge" ≈ active_domain/"shows active domain with green badge"
- "rejects invalid domain" ≈ add_domain/"rejects invalid domain on save"
- "normalizes URL input" ≈ add_domain/"normalizes domain input on save"
- "shows validation error on change" ≈ add_domain/"validates domain format on change"
- "cancel dismisses removal modal" ≈ remove/"cancels remove dismisses modal"
- "confirm removes domain and clears DB" ≈ remove/"removes domain on confirm"

**UNIQUE (2 tests):**
- "PubSub domain_status_changed updates UI" — PubSub-driven state transition
- "unauthenticated redirected to login" ≈ domain_settings/"redirects" — DUPLICATE

**Revised: 13 DUPLICATE, 1 UNIQUE**

### 6. proxy_qa_test.exs (13 tests) vs proxy_routes_test.exs (7) + proxy_tenant_resolver_test.exs (5)

**DUPLICATE (7 tests):**
- "renders with tenant business name and services" ≈ proxy_routes/"renders home page"
- "mounts LiveView with scan content" ≈ proxy_routes/"proxy /scan mounts"
- "Book Online link stays in proxy namespace" ≈ proxy_routes/"scan page Book Online links"
- "mounts LiveView under proxy" ≈ proxy_routes/"proxy /book mounts"
- "unknown slug returns 404" ≈ proxy_routes/"returns 404 for unknown slug"
- "different slugs show different business names" ≈ proxy_tenant_resolver/"resolves different companies"
- "scan pages show different tenant content" — overlap with proxy_routes scan tests

**UNIQUE (6 tests):**
- "renders tagline and service area" — detail content verification
- "form validate event works under proxy" — proxy form interaction
- "mounts or redirects gracefully under proxy" — chat under proxy
- "different slugs show different phone numbers" — phone isolation detail
- "scan page re-renders after mount" — LiveView WebSocket under proxy
- "booking form interaction works" — booking interaction under proxy

### 7. superadmin_qa_test.exs (18 tests) vs accounts_live_test.exs (10) + impersonation_test.exs (16) + security_test.exs (11)

**DUPLICATE (16 tests):**
- "admin can access dashboard" ≈ security/"authenticated admin can access /admin"
- "dashboard shows admin email" — detail overlap with accounts_live
- "shows test companies" ≈ accounts_live/"renders accounts table"
- "shows company slugs" ≈ accounts_live/"renders accounts table"
- "shows company info" ≈ accounts_live/"row click navigates to detail"
- "shows impersonate button" ≈ impersonation/"shows impersonate button"
- "start impersonation redirects to /app" ≈ impersonation/"POST redirects to /app"
- "impersonation banner visible" ≈ impersonation test (though tested differently)
- "tenant content matches impersonated company" — overlap with impersonation tenant test
- "exit impersonation returns to admin" ≈ impersonation/"clears keys and redirects"
- "/admin/accounts accessible after exit" ≈ impersonation exit tests
- "/admin returns 404 during impersonation" ≈ privilege_stacking
- "/admin/accounts returns 404 during impersonation" ≈ privilege_stacking
- "/admin/accounts/:slug returns 404 during impersonation" ≈ privilege_stacking
- "regular user gets 404 on /admin" ≈ security/"unauthenticated returns 404" + accounts/"tenant user cannot access"
- "regular user gets 404 on /admin/accounts/:slug" ≈ security
- "unauthenticated gets 404 on /admin" ≈ security/"GET /admin returns 404 without auth"
- "unauthenticated gets 404 on /admin/accounts" ≈ security/"unauthenticated"

**UNIQUE (0 tests):** All 18 are duplicates of existing non-QA tests.

## Summary

| QA File | Total | Duplicate | Unique | Action |
|---------|-------|-----------|--------|--------|
| chat_qa_test.exs | 25 | 16 | 9 | Merge 9 unique → chat_live_test.exs, delete QA |
| provision_qa_test.exs | 14 | 5 | 9 | Merge 9 unique → preview_edit_test.exs, delete QA |
| onboarding_qa_test.exs | 10 | 4 | 6 | Merge 6 unique → onboarding_live_test.exs, delete QA |
| billing_qa_test.exs | 16 | 12 | 4 | Merge 4 unique → billing_live_test.exs, delete QA |
| domain_qa_test.exs | 14 | 13 | 1 | Merge 1 unique → domain_settings_live_test.exs, delete QA |
| proxy_qa_test.exs | 13 | 7 | 6 | Merge 6 unique → proxy_routes_test.exs, delete QA |
| superadmin_qa_test.exs | 18 | 18 | 0 | Delete entirely |
| **Total** | **110** | **75** | **35** | **Net reduction: 75 tests (68%)** |

Target: ≥50% reduction (≤55 tests). Achieved: 68% reduction (35 unique tests survive as merges).

## Key Patterns Observed

1. **All QA files use `HaulWeb.ConnCase` + `Phoenix.LiveViewTest`** — same tier as non-QA
2. **QA files duplicate setup patterns** — `authenticated_conn`, `set_company_plan`, `create_company_with_content` are copied between QA and non-QA files
3. **QA files often test the same assertions with slightly different wording** — e.g., both check for "Current Plan" text
4. **Unique QA tests tend to be cross-page verifications** — e.g., billing QA checks domain page, provision QA checks tenant landing page
5. **superadmin_qa_test.exs is 100% redundant** — 3 non-QA files already cover every scenario
6. **Process.sleep patterns** in chat/provision QA tests need preservation during merge
