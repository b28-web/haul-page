# Project Overview — Active Status Board

> **All agents: update this file when you complete a ticket, surface a blocker, or learn something that affects other work.** This is the central information board. The developer reads this to understand what's happening without checking every ticket.

## Current state

**Phase:** 24 of 24 stories complete. All stories done.

**What works:** 845 tests passing, 0 failures. Full multi-tenant SaaS platform: landing page, scan page, booking form with photo upload + autocomplete, content-driven pages, notifications (email + SMS), Stripe payments + subscriptions + billing webhooks, tenant routing (subdomain + custom domain + proxy path), LiveView tenant propagation, tenant isolation, admin panel (site config, services, gallery, endorsements), self-service signup, onboarding wizard, marketing landing, CLI onboarding (`mix haul.onboard`), default content packs, custom domain settings + cert provisioning, BAML extraction pipeline, chat LiveView with live extraction, conversation persistence, onboarding agent prompt, preview/edit flow, AI cost tracking, content generation QA, superadmin panel (auth + accounts list + account detail + impersonation), proxy tenant routing + browser QA, test timing telemetry.

**What's next:** All stories complete. No remaining tickets.

## Active tickets

None — all tickets complete.

## Ready to start (unblocked)

None.

## Recently completed

| Ticket | Title | Key notes |
|--------|-------|-----------|
| T-001-01..06 | Foundation (S-001) | Phoenix 1.8.5, Ash ecosystem, CI, Dockerfile, Fly deploy, mix setup |
| T-002-01..04 | Landing Page (S-002) | Server-rendered at `/`, print stylesheet, browser QA |
| T-003-01..04 | Booking Form (S-003) | Job resource, BookingLive, photo upload, browser QA |
| T-004-01 | Accounts Domain (S-004) | Company, User, Token. Tenant provisioning. |
| T-005-01..04 | Scan Page (S-005) | ScanLive, gallery data, QR generation, browser QA |
| T-006-01..05 | Content Domain (S-006) | Ash resources, MDEx rendering, seed task, content-driven pages, browser QA |
| T-007-01..05 | Notifications (S-007) | Swoosh, SMS, Oban workers, templates, browser QA |
| T-008-01..04 | Payments (S-008) | Stripe setup, Payment Element, webhooks, browser QA |
| T-009-01..03 | Address Autocomplete (S-009) | Places proxy, autocomplete hook, browser QA |
| T-010-01..03 | Walkthrough Fixes (S-010) | Booking crash fix, gallery placeholders, smoke tests |
| T-011-01..03 | First Operator Launch (S-011) | Onboarding runbook, customer seed, monitoring |
| T-012-01..05 | Tenant Routing (S-012) | Tenant plug, LV hook, wildcard DNS, isolation tests, browser QA |
| T-013-01..06 | Content Admin (S-013) | App layout, site config editor, services/gallery/endorsements CRUD, browser QA |
| T-014-01..03 | CLI Onboarding (S-014) | mix haul.onboard, default content pack, browser QA |
| T-015-01..04 | Self-Service Signup (S-015) | Signup page, onboarding wizard, marketing landing, browser QA |
| T-016-01..04 | Subscription Billing (S-016) | Stripe subscriptions, upgrade flow, billing webhooks, browser QA |
| T-017-01..03 | Custom Domains (S-017) | Domain settings UI, cert provisioning, browser QA |
| T-018-01..04 | BAML Foundation (S-018) | baml_elixir dep, profile types, extraction function, extraction tests |
| T-019-01..06 | Conversational Onboarding (S-019) | Chat LiveView, live extraction, conversation persistence, agent prompt, fallback form, browser QA |
| T-020-01..05 | Content Generation (S-020) | Content generation, auto-provision, preview/edit, cost tracking, browser QA |
| T-021-01 | QA Walkthrough Report (S-021) | Capstone QA walkthrough complete |
| T-022-01..03 | Proxy Routing (S-022) | Path-based tenant resolution, proxy link helpers, browser QA |
| T-023-01..04 | Superadmin Panel (S-023) | Admin auth, accounts list + detail, impersonation, browser QA |
| T-024-01..04 | Test Performance (S-024) | Timing telemetry, analysis, slow test fixes, agent targeting |

## Blockers & risks

- **Dockerfile image size** — 278MB vs 100MB target. Ash ecosystem is the cause. Acceptable for now.
- **Pending TODOs in user.ex** — password reset and magic link email implementations stubbed. Not blocking.
- **baml_elixir pre-release** — pinned at 1.0.0-pre.25. Monitor for breaking changes.

## Decisions made during implementation

- **No LiveView for landing page** — server-rendered via PageController, not LiveView.
- **Operator config via `config.exs`** — business name, phone, email, services list hardcoded as defaults, overridable at runtime via env vars.
- **Haul.Cldr module added** — required by ex_money/ash_money. Not in original spec.
- **daisyUI themes disabled, custom grayscale themes defined** — dark/light via `[data-theme]` attribute + localStorage toggle.
- **Print layout: tear-off coupon strip** — 8 vertical coupons with phone number.
- **Scan page uses LiveView** — ScanLive for dynamic gallery content.
- **Booking uses LiveView** — BookingLive with real-time validation, creates Job in :lead state.
- **Content domain resources defined** — SiteConfig, Service, GalleryItem, Endorsement, Page with Ash resources and Content.Loader.
- **MDEx for Markdown rendering** — content pages rendered server-side, no client-side JS.
- **Oban for async notifications** — booking emails and SMS sent via Oban workers, not inline.
- **Notification templates as separate modules** — BookingEmail and BookingSMS modules with pure functions, workers delegate to them.
- **Tenant resolver uses subdomain extraction** — base_domain config determines how subdomains are parsed. Custom domains via Company.domain lookup.
- **Sentry logger handler** — wired in Application.start/2, captures all logged errors with request_id metadata.
- **BAML content generation uses Claude Haiku** — four separate BAML functions for cost efficiency (designed in T-020-01).
- **Chat fallback uses Chat.configured?/0** — silent redirect to signup form if LLM unavailable (designed in T-019-05).

## Cross-ticket notes

- **Ash resources now live** — Accounts (Company with domain, User, Token), Operations (Job), Content (SiteConfig, Service, GalleryItem, Endorsement, Page). Schema-per-tenant via AshPostgres :context strategy.
- **Test count: 845** — comprehensive coverage across all domains, controllers, LiveViews, workers, integrations, tenancy, and isolation.
- **All 15 browser QA tickets done** — T-002-04, T-003-04, T-005-04, T-006-05, T-007-05, T-008-04, T-009-03, T-012-05, T-013-06, T-014-03, T-015-04, T-016-04, T-017-03, T-019-06, T-020-05.
- **Playwright screenshots gitignored** — walkthrough-*.png and work artifact PNGs excluded from git.
- **Content seeding works** — `mix haul.seed` populates from priv/content/ directory. Multi-tenant: `mix haul.seed --operator customer-1`.
- **mise shims in justfile** — agent shells now find elixir/mix via `export PATH` in system.just.

---

## Quick reference

**DAG:** 94 tickets. 94 done. All complete.

**Critical path:** None — all tickets done.

**Chains:**
```
Infra:    T-001-01✓ → 02✓ → 03✓ → 04✓ → 05✓ → 06✓  (COMPLETE)
Surface:  T-002-03✓ → T-002-01✓ → T-002-02✓ → T-002-04✓  (COMPLETE)
Scan:     T-005-01✓ → 02✓ → 03✓ → 04✓  (COMPLETE)
Booking:  T-004-01✓ → T-003-01✓ → T-003-02✓ → T-003-03✓ → T-003-04✓  (COMPLETE)
Content:  T-004-01✓ → T-006-01✓ → 02✓ → 03✓ → 04✓ → 05✓  (COMPLETE)
Notify:   T-001-06✓ → T-007-01✓,02✓ → 03✓ → 04✓ → 05✓  (COMPLETE)
Payments: T-001-06✓ → T-008-01✓ → 02✓, 03✓ → 04✓  (COMPLETE)
Address:  T-001-06✓ → T-009-01✓ → 02✓ → 03✓  (COMPLETE)
Fixes:    T-010-01✓, T-010-02✓ → T-010-03✓  (COMPLETE)

--- SaaS Platform (E-010) ---
Phase 1:  T-011-01✓, T-011-02✓, T-011-03✓  (COMPLETE)
Phase 2:  T-012-01✓ → 02✓ → 04✓, T-012-03✓ → T-012-05✓  (COMPLETE)
          T-013-01✓ → 02✓..05✓ → T-013-06✓  (COMPLETE)
          T-014-01✓, T-014-02✓ → T-014-03✓  (COMPLETE)
Phase 3:  T-015-01✓ → 02✓, T-015-03✓ → T-015-04✓  (COMPLETE)
          T-016-01✓ → 02✓, 03✓ → T-016-04✓  (COMPLETE)
          T-017-01✓ → 02✓ → T-017-03✓  (COMPLETE)

--- AI Onboarding (E-011) ---
Phase 1:  T-018-01✓ → T-018-02✓ → T-018-03✓ → T-018-04✓  (COMPLETE)
Phase 2:  T-019-01✓ → T-019-02✓ + T-019-03✓
          T-019-04✓, T-019-05✓ (fallback form)
          T-019-02✓ + T-019-05✓ → T-019-06✓ (browser-qa)
Phase 3:  T-020-01✓ (content gen) → T-020-02✓ (auto-provision) → T-020-03✓ (preview/edit)
          T-020-03✓ → T-020-05✓ (browser-qa) + T-020-04✓ (cost tracking)

--- Capstone ---
All browser-qa tickets → T-021-01✓ (walkthrough report + dev briefing)

--- Proxy Routing (S-022) ---
S-022: T-022-01✓ → T-022-02✓ → T-022-03✓  (COMPLETE)

--- Superadmin (S-023) ---
S-023: T-023-01✓ → T-023-02✓ → T-023-03✓ → T-023-04✓  (COMPLETE)

--- Test Performance (S-024) ---
S-024: T-024-01✓ → T-024-02✓ → T-024-03✓ → T-024-04✓  (COMPLETE)
```

**Stories:**
- S-001 Foundation — COMPLETE (6/6)
- S-002 Landing Page — COMPLETE (4/4)
- S-003 Booking Form — COMPLETE (4/4)
- S-004 Accounts Domain — COMPLETE (1/1)
- S-005 Scan Page — COMPLETE (4/4)
- S-006 Content Domain — COMPLETE (5/5)
- S-007 Notifications — COMPLETE (5/5)
- S-008 Payments — COMPLETE (4/4)
- S-009 Address Autocomplete — COMPLETE (3/3)
- S-010 Walkthrough Fixes — COMPLETE (3/3)
- S-011 First Operator Launch — COMPLETE (3/3)
- S-012 Tenant Routing — COMPLETE (5/5)
- S-013 Content Admin — COMPLETE (6/6)
- S-014 CLI Onboarding — COMPLETE (3/3)
- S-015 Self-Service Signup — COMPLETE (4/4)
- S-016 Subscription Billing — COMPLETE (4/4)
- S-017 Custom Domains — COMPLETE (3/3)
- S-018 BAML Foundation — COMPLETE (4/4)
- S-019 Conversational Onboarding — COMPLETE (6/6)
- S-020 Content Generation — COMPLETE (5/5)
- S-021 QA Walkthrough Report — COMPLETE (1/1)
- S-022 Proxy Routing — COMPLETE (3/3)
- S-023 Superadmin Panel — COMPLETE (4/4)
- S-024 Test Performance — COMPLETE (4/4)

**Epics (ongoing health):**
- E-001 Dev environment — GOOD (all contributing stories complete)
- E-002 Deploy pipeline — GOOD (all contributing stories complete)
- E-003 Public surface — GOOD (all contributing stories complete)
- E-004 Domain model — GOOD (all contributing stories complete)
- E-005 Content system — GOOD (all contributing stories complete)
- E-006 First customer — GOOD (capstone QA complete)
- E-007 Demo instance — GOOD (all contributing stories complete)
- E-008 Data security — GOOD (S-023 impersonation audit logging complete)
- E-009 Service integrations — GOOD (all contributing stories complete)
- E-010 SaaS platform — GOOD (all contributing stories complete)
- E-011 AI onboarding — GOOD (all contributing stories complete)
- E-012 Dev tenant preview — GOOD (S-022 complete)
- E-013 Developer agent experience — GOOD (S-023 complete, S-024 complete)
