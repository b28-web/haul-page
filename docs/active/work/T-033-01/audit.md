# T-033-01 Audit: Mock Candidates

> 975 tests, 92.7s wall-clock. 109 files: 36 ExUnit.Case, 27 DataCase, 46 ConnCase.

---

## Section 1: DataCase Files

| File | Tests | Time | DB-Req | Mock | Unit | Recommendation | Notes |
|------|-------|------|--------|------|------|----------------|-------|
| accounts/company_test.exs | 7 | 1.1s | 7 | 0 | 0 | KEEP | Schema provisioning, unique slug |
| accounts/user_test.exs | 6 | 1.0s | 4 | 2 | 0 | KEEP | Password hashing, role defaults |
| accounts/security_test.exs | 11 | 2.1s | 11 | 0 | 0 | KEEP | Policy enforcement, tenant isolation |
| operations/job_test.exs | 8 | 1.3s | 1 | 7 | 0 | SPLIT | 7 validation tests are Ash actions — ticket says keep DB |
| operations/changes/enqueue_notifications_test.exs | 1 | 0.2s | 1 | 0 | 0 | KEEP | Oban enqueue on create |
| onboarding_test.exs | 13 | 0.8s | 3 | 5 | 5 | SPLIT | derive_slug (4), site_url (1) are pure functions |
| content/site_config_test.exs | 5 | 0.8s | 5 | 0 | 0 | KEEP | Ash validation = DB-required per ticket |
| content/service_test.exs | 5 | 0.8s | 5 | 0 | 0 | KEEP | FK constraint, sort_order query |
| content/gallery_item_test.exs | 4 | 0.6s | 4 | 0 | 0 | KEEP | Ash validation = DB-required |
| content/endorsement_test.exs | 7 | 1.1s | 7 | 0 | 0 | KEEP | Ash validation = DB-required |
| content/page_test.exs | 8 | 1.3s | 8 | 0 | 0 | KEEP | Unique slug, markdown rendering via Ash |
| content/seeder_test.exs | 6 | 1.1s | 4 | 0 | 2 | SPLIT | parse_frontmatter (2) are pure string parsing |
| tenant_isolation_test.exs | 10 | 1.9s | 10 | 0 | 0 | KEEP | Core security backbone |
| ai/edit_applier_test.exs | 10 | 2.1s | 7 | 3 | 0 | MOCK | 3 tests could mock Ash reads/writes |
| ai/provisioner_test.exs | 7 | 1.0s | 6 | 1 | 0 | MOCK | 1 validation test mockable |
| ai/conversation_test.exs | 16 | async | 7 | 9 | 0 | KEEP | Already async:true |
| ai/cost_tracker_test.exs | 24 | async | 7 | 5 | 12 | SPLIT | 12 pure math already async, could extract |
| workers/check_dunning_grace_test.exs | 3 | 0.5s | 0 | 3 | 0 | MOCK | All 3: datetime arithmetic + Company update |
| workers/provision_cert_test.exs | 5 | 1.0s | 0 | 5 | 0 | MOCK | Cert API stubbed, all mockable |
| workers/provision_site_test.exs | 3 | 0.2s | 2 | 1 | 0 | MOCK | enqueue is pure; perform needs Provisioner |
| workers/send_booking_email_test.exs | 3 | 0.5s | 0 | 3 | 0 | MOCK | Swoosh assertions only |
| workers/send_booking_sms_test.exs | 2 | 0.3s | 0 | 2 | 0 | MOCK | Process mailbox assertions only |
| workers/cleanup_conversations_test.exs | 4 | async | 4 | 0 | 0 | KEEP | Already async:true, DB-required |
| admin/bootstrap_test.exs | 4 | async | 1 | 3 | 0 | KEEP | Already async:true |
| mix/tasks/haul/onboard_test.exs | 3 | 0.6s | 3 | 0 | 0 | KEEP | CLI integration |

**DataCase Totals:** 169 tests | 106 DB-required | 49 mock-feasible | 19 pure-unit extractable

---

## Section 2: ConnCase Files

### Already async:true (no action needed)

| File | Tests | Time | Notes |
|------|-------|------|-------|
| controllers/error_json_test.exs | 2 | <0.1s | Pure rendering |
| controllers/error_html_test.exs | 2 | <0.1s | Pure rendering |
| controllers/health_controller_test.exs | 1 | <0.1s | Stateless endpoint |
| controllers/marketing_page_test.exs | 7 | <0.1s | Static HTML |
| controllers/places_controller_test.exs | 8 | <0.1s | Adapter sandbox |
| controllers/qr_controller_test.exs | 10 | <0.1s | Pure generation |
| controllers/debug_controller_test.exs | 1 | <0.1s | Error handling |
| live/admin/security_test.exs | 11 | 0.4s | Auth checks, no state |
| live/admin/impersonation_test.exs | 13 | 2.6s | Session helpers (could be faster) |

**Subtotal: 55 tests, already optimal.**

### async:false ConnCase Files

| File | Tests | Time | DB-Req | Render | Mock | Recommendation | Notes |
|------|-------|------|--------|--------|------|----------------|-------|
| live/chat_live_test.exs | 22 | 2.7s | 0 | 22 | 0 | DEDUP/ASYNC | All render-only, overlaps chat_qa |
| live/chat_qa_test.exs | 25 | 4.0s | 0 | 25 | 0 | DEDUP | All render-only, 11 overlap chat_live |
| live/preview_edit_test.exs | 13 | 5.5s | 7 | 6 | 0 | SPLIT | 6 render-only could separate |
| live/provision_qa_test.exs | 14 | 4.7s | 5 | 9 | 0 | DEDUP | 9 render-only; 5 overlap preview_edit |
| live/onboarding_qa_test.exs | 10 | 1.9s | 10 | 0 | 0 | KEEP | Different scope from onboarding_live |
| live/booking_live_test.exs | 14 | 2.3s | 3 | 9 | 2 | KEEP | Mixed, needs tenant setup |
| live/booking_live_upload_test.exs | 6 | 1.0s | 0 | 6 | 0 | KEEP | Upload requires live conn |
| live/booking_live_autocomplete_test.exs | 8 | 1.5s | 0 | 6 | 2 | KEEP | Places sandbox |
| live/payment_live_test.exs | 7 | 1.2s | 3 | 4 | 0 | KEEP | Stripe integration |
| live/scan_live_test.exs | 9 | 1.7s | 8 | 1 | 0 | KEEP | Content reads |
| live/tenant_hook_test.exs | 5 | 0.9s | 4 | 1 | 0 | KEEP | Multi-tenant hook |
| live/app/onboarding_live_test.exs | 14 | 2.6s | 2 | 12 | 0 | SPLIT | 12 render-only behind auth setup |
| live/app/signup_live_test.exs | 11 | 0.8s | 1 | 10 | 0 | ASYNC | Minimal DB, rate limiting state |
| live/app/signup_flow_test.exs | 14 | 0.6s | 14 | 0 | 0 | KEEP | Full signup E2E |
| live/app/dashboard_live_test.exs | 7 | 1.0s | 5 | 2 | 0 | KEEP | Auth context |
| live/app/site_config_live_test.exs | 8 | 1.2s | 7 | 1 | 0 | KEEP | CRUD LiveView |
| live/app/services_live_test.exs | 11 | 1.6s | 9 | 2 | 0 | KEEP | CRUD + reorder |
| live/app/gallery_live_test.exs | 11 | 1.9s | 10 | 1 | 0 | KEEP | CRUD + uploads |
| live/app/endorsements_live_test.exs | 11 | 1.7s | 9 | 2 | 0 | KEEP | CRUD + reorder |
| live/app/billing_live_test.exs | 14 | 2.2s | 8 | 6 | 0 | KEEP | Plan state |
| live/app/billing_qa_test.exs | 16 | 2.5s | 6 | 10 | 0 | DEDUP | 10 overlap billing_live |
| live/app/domain_settings_live_test.exs | 16 | 2.5s | 10 | 6 | 0 | KEEP | Domain CRUD |
| live/app/domain_qa_test.exs | 14 | 2.2s | 5 | 9 | 0 | DEDUP | 9 overlap domain_settings |
| live/app/login_live_test.exs | 2 | <0.1s | 1 | 1 | 0 | ASYNC | Minimal |
| live/admin/accounts_live_test.exs | 10 | 1.4s | 7 | 3 | 0 | KEEP | Admin auth |
| live/admin/account_detail_live_test.exs | 8 | 1.2s | 6 | 2 | 0 | KEEP | Admin auth |
| live/admin/superadmin_qa_test.exs | 18 | 3.8s | 12 | 6 | 0 | KEEP | E2E security |
| live/proxy_qa_test.exs | 13 | 2.4s | 8 | 5 | 0 | KEEP | Proxy integration |
| controllers/page_controller_test.exs | 8 | 1.5s | 8 | 0 | 0 | KEEP | Content rendering |
| controllers/webhook_controller_test.exs | 7 | 1.0s | 7 | 0 | 0 | KEEP | Webhook handling |
| controllers/billing_webhook_controller_test.exs | 14 | 2.3s | 14 | 0 | 0 | KEEP | Billing webhooks |
| plugs/tenant_resolver_test.exs | 14 | 0.8s | 8 | 0 | 6 | ASYNC | Light company creates |
| plugs/proxy_routes_test.exs | 7 | 1.0s | 5 | 0 | 2 | ASYNC | Light company creates |
| plugs/proxy_tenant_resolver_test.exs | 7 | 0.5s | 4 | 0 | 3 | ASYNC | Light company creates |
| smoke_test.exs | 5 | 1.0s | 5 | 0 | 0 | KEEP | Smoke test |

**ConnCase Totals (async:false):** 393 tests | 216 DB-req | 164 render-only | 15 mock-feasible

---

## Section 3: QA Overlap Report

### chat_qa_test.exs ↔ chat_live_test.exs (11 overlaps)

| QA Test | Non-QA Test | Verdict |
|---------|------------|---------|
| renders header with title and manual signup link | renders chat page at /start | REMOVE from QA |
| shows welcome message when no messages exist | starts with empty message list | REMOVE from QA |
| profile sidebar shows empty state with 0 of 7 fields | renders profile sidebar with empty state | REMOVE from QA |
| input is disabled during streaming | disables input during streaming | REMOVE from QA |
| input re-enables after streaming completes | re-enables input after streaming completes | REMOVE from QA |
| services list renders individual service names | services list renders in profile panel | REMOVE from QA |
| differentiators list renders | differentiators render in profile panel | REMOVE from QA |
| shows profile complete CTA when required fields present | profile complete CTA appears... | REMOVE from QA |
| shows message limit error at max messages | enforces max message limit | REMOVE from QA |
| first message AI error redirects to signup with flash | redirects to /app/signup with flash... | REMOVE from QA |
| redirects to /app/signup when chat is not configured | redirects to /app/signup when... | REMOVE from QA |

### billing_qa_test.exs ↔ billing_live_test.exs (10 overlaps)

| QA Test | Non-QA Test | Verdict |
|---------|------------|---------|
| renders all four tier comparison cards | renders billing page with plan cards | REMOVE from QA |
| displays Starter as current plan with Free pricing | shows current plan as highlighted | REMOVE from QA |
| shows upgrade buttons for Pro, Business, Dedicated | upgrade shows correct buttons... | REMOVE from QA |
| shows feature labels on plan cards | shows feature labels on plan cards | REMOVE from QA |
| does not show Manage Payment Methods without Stripe customer | manage billing button not shown... | REMOVE from QA |
| clicking Upgrade to Pro creates sandbox customer... | upgrade from starter triggers checkout... | REMOVE from QA |
| upgrading existing subscription updates plan immediately | upgrade with existing subscription... | REMOVE from QA |
| confirming downgrade changes plan back to Starter | confirming downgrade changes plan | REMOVE from QA |
| unauthenticated user is redirected to login | redirects unauthenticated users to login | REMOVE from QA |
| returning with session_id shows success flash | session_id param shows success flash | REMOVE from QA |

### domain_qa_test.exs ↔ domain_settings_live_test.exs (9 overlaps)

| QA Test | Non-QA Test | Verdict |
|---------|------------|---------|
| shows upgrade prompt instead of domain form | shows upgrade prompt for starter plan | REMOVE from QA |
| still shows current subdomain address | shows subdomain address | REMOVE from QA |
| pending state: shows CNAME instructions... | shows CNAME instructions for pending domain | REMOVE from QA |
| active state: shows green badge and verified tag | shows active domain with green badge | REMOVE from QA |
| rejects invalid domain on submit | rejects invalid domain on save | REMOVE from QA |
| normalizes URL input on save | normalizes domain input on save | REMOVE from QA |
| cancel dismisses removal modal | cancels remove dismisses modal | REMOVE from QA |
| confirm removes domain and clears DB | removes domain on confirm | REMOVE from QA |
| unauthenticated user is redirected to login | redirects unauthenticated users to login | REMOVE from QA |

**Total overlapping tests: 30** (11 chat + 10 billing + 9 domain)

---

## Section 4: Module-Level Action Items

### T-033-02: Extract Pure Logic (SPLIT)

| File | Tests to Extract | Savings | What to Extract |
|------|-----------------|---------|-----------------|
| onboarding_test.exs | 5 | ~0.3s | derive_slug/1 (4 tests), site_url/1 (1 test) → new unit module |
| content/seeder_test.exs | 2 | ~0.2s | parse_frontmatter tests → new unit module |
| ai/cost_tracker_test.exs | 12 | already async | estimate_tokens, calculate_cost, model_for → new unit module |

**Total: 19 tests extractable to ExUnit.Case async:true**

### T-033-03: Mock Service Layer (MOCK)

| File | Tests | Current Time | Mock Strategy |
|------|-------|-------------|---------------|
| workers/check_dunning_grace_test.exs | 3 | 0.5s | Mock Company lookup + Ash.update! |
| workers/provision_cert_test.exs | 5 | 1.0s | Mock Company lookup (cert API already stubbed) |
| workers/send_booking_email_test.exs | 3 | 0.5s | Mock Job lookup (Swoosh already mocked) |
| workers/send_booking_sms_test.exs | 2 | 0.3s | Mock Job lookup (SMS already mocked) |
| ai/edit_applier_test.exs | 3 | ~0.6s | Mock Ash reads for non-DB-mutation tests |
| ai/provisioner_test.exs | 1 | ~0.1s | Mock validation path only |
| workers/provision_site_test.exs | 1 | ~0.1s | Mock enqueue (pure struct) |

**Total: 18 tests mockable, ~3.1s potential savings**

### T-033-04: Dedup QA Tests (DEDUP)

| QA File | Overlapping | Unique | Action |
|---------|------------|--------|--------|
| chat_qa_test.exs | 11 | 14 | Remove 11 overlapping tests |
| billing_qa_test.exs | 10 | 6 | Remove 10 overlapping tests |
| domain_qa_test.exs | 9 | 5 | Remove 9 overlapping tests |

**Total: 30 tests to remove, ~5.5s savings** (proportional to file times)

### T-033-05: Async Unlock (ASYNC)

| File | Tests | Current Time | Prerequisite |
|------|-------|-------------|--------------|
| chat_live_test.exs | 22 | 2.7s | After QA dedup |
| plugs/tenant_resolver_test.exs | 14 | 0.8s | None |
| plugs/proxy_routes_test.exs | 7 | 1.0s | None |
| plugs/proxy_tenant_resolver_test.exs | 7 | 0.5s | None |
| app/login_live_test.exs | 2 | <0.1s | None |
| app/signup_live_test.exs | 11 | 0.8s | Rate limiter state isolation |

**Total: 63 tests, ~5.8s of sync time → async** (wall-clock savings depend on parallelism)

---

## Summary

| Ticket | Action | Tests Affected | Est. Time Savings |
|--------|--------|---------------|-------------------|
| T-033-02 | Extract pure logic | 19 | ~0.5s (plus correctness) |
| T-033-03 | Mock service layer | 18 | ~3.1s |
| T-033-04 | Dedup QA tests | 30 | ~5.5s |
| T-033-05 | Async unlock | 63 | ~5.8s wall-clock |
| **Total** | | **130** | **~14.9s** |

Combined with current 92.7s suite, target of ≤60s for T-033-05 is achievable.
