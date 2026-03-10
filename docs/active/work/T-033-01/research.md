# T-033-01 Research: Audit Mock Candidates

## Test Suite Snapshot

- **975 tests**, 0 failures, 92.7s wall-clock (88.2s sync, 4.4s async)
- **109 test files**: 36 ExUnit.Case (unit), 27 DataCase (resource), 46 ConnCase (integration)
- **55 files async:true**, 60 async:false, 3 unspecified (default false)

## Per-File Timing (top 20 slowest)

| File | Time | Tests | Tier |
|------|------|-------|------|
| preview_edit_test.exs | 5.5s | 13 | ConnCase |
| provision_qa_test.exs | 4.7s | 14 | ConnCase |
| chat_qa_test.exs | 4.0s | 25 | ConnCase |
| superadmin_qa_test.exs | 3.8s | 18 | ConnCase |
| chat_live_test.exs | 2.7s | 22 | ConnCase |
| onboarding_live_test.exs | 2.6s | 14 | ConnCase |
| impersonation_test.exs | 2.6s | 16 | ConnCase |
| domain_settings_live_test.exs | 2.5s | 16 | ConnCase |
| billing_qa_test.exs | 2.5s | 16 | ConnCase |
| proxy_qa_test.exs | 2.4s | 13 | ConnCase |
| booking_live_test.exs | 2.3s | 14 | ConnCase |
| billing_webhook_controller_test.exs | 2.3s | 14 | ConnCase |
| billing_live_test.exs | 2.2s | 14 | ConnCase |
| domain_qa_test.exs | 2.2s | 14 | ConnCase |
| edit_applier_test.exs | 2.1s | 11 | DataCase |
| security_test.exs | 2.1s | 11 | DataCase |
| onboarding_qa_test.exs | 1.9s | 10 | ConnCase |
| tenant_isolation_test.exs | 1.9s | 10 | DataCase |
| gallery_live_test.exs | 1.9s | 11 | ConnCase |
| scan_live_test.exs | 1.7s | 9 | ConnCase |

## Existing Unit Tests (ExUnit.Case, async: true)

36 files, ~210 tests, <1s total. Already fast. These came from S-028 (extract domain logic):
- AI modules: edit_classifier, error_classifier, message, onboarding_prompt, operator_profile, profile_mapper, prompt, extractor, content_generator
- Domain: billing, domains, formatting, payments, sortable, config, mailer, sms, storage
- Web helpers: helpers, proxy_helpers
- Workers: profile_serializer
- Content: defaults, init_task, loader, markdown
- Admin: account_helpers, init_task
- Other: rate_limiter, timing_formatter, sentry_config

## Setup Patterns

### `create_authenticated_context/0` (~200ms)
Used by: all app/ LiveView tests (dashboard, site_config, services, gallery, endorsements, billing, domain_settings, onboarding). Creates Company → provisions tenant schema → creates User → returns conn with auth.

### `Onboarding.run/1` (~200ms)
Used by: onboarding_test, onboarding_qa_test, provisioner_test indirectly. Creates Company + tenant + user + seeds content.

### Tenant schema create+cleanup (~200ms overhead per test file)
Most DataCase and ConnCase files create companies/tenants in setup and drop schemas in on_exit. This is the dominant cost.

## QA File Overlap Analysis

7 QA files, 110 tests, 22.4s total:

| QA File | Tests | Time | Non-QA Counterpart | Overlap |
|---------|-------|------|-------------------|---------|
| chat_qa_test.exs | 25 | 4.0s | chat_live_test.exs (22 tests) | ~11 tests (44%) |
| billing_qa_test.exs | 16 | 2.5s | billing_live_test.exs (14 tests) | ~10 tests (62%) |
| domain_qa_test.exs | 14 | 2.2s | domain_settings_live_test.exs (16 tests) | ~9 tests (64%) |
| superadmin_qa_test.exs | 18 | 3.8s | accounts/security/impersonation (split) | low |
| provision_qa_test.exs | 14 | 4.7s | none (E2E pipeline) | none |
| proxy_qa_test.exs | 13 | 2.4s | none (proxy integration) | none |
| onboarding_qa_test.exs | 10 | 1.9s | onboarding_live_test.exs (different scope) | low |

**~30 QA tests** overlap with existing non-QA tests (chat: 11, billing: 10, domain: 9).

## DataCase Files — Mock Feasibility

### High mock potential (pure logic behind DB)
- **check_dunning_grace_test** (3 tests, 0.5s): Pure datetime arithmetic. All 3 mockable.
- **provision_cert_test** (5 tests, 1.0s): Cert API boundary, already stubbed. All 5 mockable.
- **send_booking_email_test** (3 tests, 0.5s): Swoosh assertions. All 3 mockable.
- **send_booking_sms_test** (2 tests, 0.3s): Process mailbox assertions. All 2 mockable.
- **cost_tracker_test** (24 tests, 0.4s): Already async:true. 12 tests are pure math.

### Partial mock potential
- **edit_applier_test** (10 tests, 2.1s): 3 mock-feasible, 7 DB-required (verify state changes).
- **provisioner_test** (7 tests, 1.0s): 1 mock-feasible (validation), 6 DB-required.
- **provision_site_test** (3 tests, 0.2s): 1 mock-feasible (enqueue), 2 DB-required.
- **cleanup_conversations_test** (4 tests, already async): All DB-required (datetime queries).
- **job_test** (8 tests, 1.3s): 7 mock-feasible (validation), 1 DB-required.
- **onboarding_test** (13 tests, 0.8s): 5 pure functions (derive_slug, site_url), 5 validation, 3 DB-required.
- **content tests** (page, service, endorsement, gallery_item, site_config — 29 tests, 4.1s): Mostly validation, but Ash validations run through DB.

### Not mockable (must remain DB)
- **tenant_isolation_test** (10 tests, 1.9s): Core security. All DB-required.
- **security_test** (11 tests, 2.1s): Policy enforcement. All DB-required.
- **company_test** (7 tests, 1.1s): Schema provisioning. All DB-required.
- **seeder_test** (6 tests, 1.1s): 4 DB-required, 2 pure (YAML parsing).

## ConnCase Files — Render-Only Potential

### Entirely render-only (no DB assertions)
- **chat_live_test.exs** (22 tests, 2.7s): All render-only. Uses ChatSandbox mock.
- **chat_qa_test.exs** (25 tests, 4.0s): All render-only. Uses ChatSandbox mock.

### Mostly render-only
- **onboarding_live_test.exs** (14 tests, 2.6s): 12 render-only, 2 DB-required.
- **provision_qa_test.exs** (14 tests, 4.7s): 7 render-only, 5 DB-required.
- **preview_edit_test.exs** (13 tests, 5.5s): 6 render-only, 7 DB-required.
- **signup_live_test.exs** (11 tests, 0.8s): 10 render-only, 1 DB-required.

### Already async:true ConnCase
- admin/security_test.exs (11 tests), admin/impersonation_test.exs (13 tests)
- error_json, error_html, health_controller, marketing_page, places_controller, qr_controller, debug_controller
