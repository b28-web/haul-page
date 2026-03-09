# Project Overview — Active Status Board

> **All agents: update this file when you complete a ticket, surface a blocker, or learn something that affects other work.** This is the central information board. The developer reads this to understand what's happening without checking every ticket.

## Current state

**Phase:** Foundation (S-001) complete. Landing page (S-002) complete. Accounts domain (S-004) complete. Scan page (S-005) complete. Booking form (S-003) complete. Content domain (S-006) complete. Notifications (S-007) 4/5 done, T-007-05 (browser-qa) in progress. Payments (S-008) 3/4 done — T-008-03 webhooks done, T-008-04 (browser-qa) in progress. Address autocomplete (S-009) 1/3 done — T-009-01 done, T-009-02 implementing. Walkthrough fixes (S-010) 1/3 done — T-010-01 fixed.

**What works:** Dev server healthy on port 4000. 201 tests passing, 0 failures. All work committed and pushed. Ash resources live: Accounts domain (Company, User, Token), Operations domain (Job with state machine + payment_intent_id), Content domain (SiteConfig, Service, GalleryItem, Endorsement, Page). Content rendering via MDEx. Seed task. Content-driven pages. Photo upload. Swoosh email + SMS client. Oban notification workers with email/SMS templates. Stripe payment processing with sandbox adapter. Payment LiveView at `/pay/:job_id`. Stripe webhook controller. Google Places proxy. Address autocomplete hook. Landing page at `/`. Scan page at `/scan`. Booking at `/book` with photo upload and autocomplete.

**What's next:**
- **Notifications finish:** T-007-05 (browser-qa) in progress
- **Payments finish:** T-008-04 (browser-qa) in progress
- **Address autocomplete:** T-009-02 implementing → T-009-03
- **Bugfixes:** T-010-02 (gallery-placeholders) researching → T-010-03 (smoke test)
- **SaaS platform:** T-012-01 (tenant-plug), T-013-01 (app-layout) ready — gate most of Phase 2

## Active tickets

| Ticket | Title | Phase | Agent notes |
|--------|-------|-------|-------------|
| T-007-05 | notification-browser-qa | implement | Work artifacts and tests committed |
| T-008-04 | payment-browser-qa | implement | Work artifacts committed |
| T-009-02 | autocomplete-hook | implement | JS hook and LiveView integration committed |
| T-010-02 | gallery-placeholders | research | Research artifacts committed |

## Ready to start (unblocked)

| Ticket | Title | Blocked by (done) |
|--------|-------|--------------------|
| T-011-01 | onboarding-runbook | T-001-06 ✓ |
| T-011-02 | customer-seed-content | T-006-03 ✓ |
| T-011-03 | monitoring-setup | T-001-05 ✓ |
| T-012-01 | tenant-plug | T-004-01 ✓ |
| T-013-01 | app-layout | T-004-01 ✓ |
| T-014-02 | default-content-pack | T-006-03 ✓ |
| T-018-01 | baml-dep-setup | T-001-06 ✓ |

## Recently completed

| Ticket | Title | Key notes |
|--------|-------|-----------|
| T-001-01 | scaffold-phoenix | Phoenix 1.8.5 + full Ash ecosystem. Haul.Cldr for ex_money. |
| T-001-02 | version-pinning | mise.toml: Erlang 28, Elixir 1.19. CI env vars synced. |
| T-001-03 | ci-pipeline | GH Actions: test (Postgres 16) + quality (format, credo, dialyzer). |
| T-001-04 | dockerfile | Multi-stage Dockerfile, 278MB. migrate_and_start script. |
| T-001-05 | fly-deploy | fly.toml configured, health check at /healthz, scale-to-zero. |
| T-001-06 | mix-setup | mix setup works end-to-end. Unblocks service integrations. |
| T-002-03 | tailwind-setup | Google Fonts. daisyUI remapped to grayscale dark theme. |
| T-002-01 | landing-page-markup | Four-section page at `/`. Server-rendered. Dark grayscale. |
| T-002-02 | print-stylesheet | White bg/black text for print. Tear-off coupon strip. |
| T-002-04 | browser-qa | Playwright-based QA for landing page passed. |
| T-004-01 | company-user-resources | Accounts domain: Company (tenant root), User, Token. Tenant provisioning. |
| T-003-01 | job-resource | Operations domain: Job with state machine (lead→scheduled→completed). |
| T-003-02 | booking-liveview | Booking LiveView at `/book`. Creates Job in :lead state. |
| T-003-03 | photo-upload | LiveView upload with Storage module. photo_urls field on Job. |
| T-003-04 | browser-qa | Booking form Playwright QA passed. |
| T-005-01 | scan-page-layout | Scan page LiveView at `/scan`. Dark theme, gallery, CTA. |
| T-005-02 | gallery-data | Gallery data model for before/after photos. |
| T-005-03 | qr-generation | QR code generation for scan page URL. QrController. |
| T-005-04 | browser-qa | Scan page Playwright QA passed. |
| T-006-01 | content-resources | Content Ash domain: SiteConfig, Service, GalleryItem, Endorsement, Page. |
| T-006-02 | mdex-rendering | MDEx-based Markdown rendering for content pages. |
| T-006-03 | seed-task | mix haul.seed task populates content from priv/content/ YAML+MD files. |
| T-006-04 | content-driven-pages | PageController renders content pages from DB via Content domain. |
| T-006-05 | browser-qa | Content pages Playwright QA passed. |
| T-007-01 | swoosh-setup | Swoosh mailer configured with Mailgun adapter. |
| T-007-02 | sms-client | SMS client module with Twilio adapter. |
| T-007-03 | notifier-oban | Oban workers: SendBookingEmail, SendBookingSMS. Job state change triggers. |
| T-007-04 | notification-templates | BookingEmail + BookingSMS template modules. Operator alerts + customer confirmations. |
| T-008-01 | stripe-setup | Stripe deps (stripity_stripe) installed and configured. Sandbox adapter. |
| T-008-02 | payment-element | Payment LiveView at /pay/:job_id with Stripe Payment Element JS hook. |
| T-008-03 | stripe-webhooks | Webhook controller with signature verification. payment_intent.succeeded/failed handling. |
| T-009-01 | places-proxy | Google Places API proxy with sandbox adapter. PlacesController. |
| T-010-01 | fix-booking-crash | Fixed missing @max_photos assign in BookingLive mount. |

## Blockers & risks

- **Dockerfile image size** — 278MB vs 100MB target. Ash ecosystem is the cause. Acceptable for now.
- **Pending TODOs in user.ex** — password reset and magic link email implementations reference Haul.Mailer but are stubbed. Not blocking anything currently.

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

## Cross-ticket notes

- **Ash resources now live** — Accounts (Company, User, Token), Operations (Job), Content (SiteConfig, Service, GalleryItem, Endorsement, Page). Schema-per-tenant via AshPostgres :context strategy.
- **Test count: 201** — substantial test coverage across accounts, operations, content, controllers, storage, notifications, payments, places.
- **Browser QA tickets completed:** T-002-04 (landing page), T-003-04 (booking), T-005-04 (scan page), T-006-05 (content pages) — all passed.
- **Remaining browser QA:** T-007-05 (notifications), T-008-04 (payments), T-009-03 (address autocomplete), T-012-05 (tenant routing), T-013-06 (content admin), T-014-03 (CLI onboard), T-015-04 (signup flow), T-016-04 (billing), T-017-03 (custom domains), T-019-06 (chat onboarding), T-020-05 (AI provision pipeline).
- **Playwright screenshots gitignored** — walkthrough-*.png and work artifact PNGs excluded from git. Agents produce them locally but they don't go to GitHub.
- **Content seeding works** — `mix haul.seed` populates from priv/content/ directory (YAML configs, Markdown pages).
- **All work committed and pushed** — 201 tests, 0 failures. Clean working tree (only test upload artifacts untracked).

---

## Quick reference

**DAG:** 83 tickets. 34 done, 4 in progress, 11 ready, 34 blocked. Max 2 concurrent.

**Chains:**
```
Infra:    T-001-01✓ → 02✓ → 03✓ → 04✓ → 05✓ → 06✓  (COMPLETE)
Surface:  T-002-03✓ → T-002-01✓ → T-002-02✓ → T-002-04✓  (COMPLETE)
Scan:     T-005-01✓ → 02✓ → 03✓ → 04✓  (COMPLETE)
Booking:  T-004-01✓ → T-003-01✓ → T-003-02✓ → T-003-03✓ → T-003-04✓  (COMPLETE)
Content:  T-004-01✓ → T-006-01✓ → 02✓ → 03✓ → 04✓ → 05✓  (COMPLETE)
Notify:   T-001-06✓ → T-007-01✓,02✓ → 03✓ → 04✓ → 05*
Payments: T-001-06✓ → T-008-01✓ → 02✓, 03✓ → 04*
Address:  T-001-06✓ → T-009-01✓ → 02* → 03
Fixes:    T-010-01✓, T-010-02* → T-010-03

--- SaaS Platform (E-010) ---
Phase 1:  T-011-01 (runbook), T-011-02 (customer seed), T-011-03 (monitoring)
Phase 2:  T-012-01 (tenant plug) → T-012-02 (LV tenant) → T-012-04 (isolation tests)
          T-012-01 → T-012-03 (wildcard DNS)
          T-012-02 + T-012-03 → T-012-05 (🎭 browser-qa)
          T-013-01 (app layout) → T-013-02..05 (content admin CRUD) → T-013-06 (🎭 browser-qa)
          T-014-01 (mix onboard) + T-014-02 (default content) → T-014-03 (🎭 browser-qa)
Phase 3:  T-015-01 (signup) → T-015-02 (wizard) + T-015-03 (marketing landing) → T-015-04 (🎭 browser-qa)
          T-016-01 (stripe subs) → T-016-02 (upgrade flow) → T-016-03 (billing webhooks) → T-016-04 (🎭 browser-qa)
          T-017-01 (domain UI) → T-017-02 (cert provisioning) → T-017-03 (🎭 browser-qa)

--- AI Onboarding (E-011) ---
Phase 1:  T-018-01 (baml dep) → T-018-02 (profile types) → T-018-03 (extraction) → T-018-04 (tests)
Phase 2:  T-019-01 (chat LV) → T-019-02 (live extraction) + T-019-03 (persistence)
          T-019-04 (agent prompt), T-019-05 (fallback form)
          T-019-02 + T-019-05 → T-019-06 (🎭 browser-qa)
Phase 3:  T-020-01 (content gen) → T-020-02 (auto-provision) → T-020-03 (preview/edit)
          T-020-03 → T-020-05 (🎭 browser-qa) + T-020-04 (cost tracking)

--- Capstone ---
All 15 🎭 browser-qa tickets → T-021-01 (walkthrough report + dev briefing)
```
*in progress

**Stories:**
- S-001 Foundation — COMPLETE (6/6)
- S-002 Landing Page — COMPLETE (4/4)
- S-003 Booking Form — COMPLETE (4/4)
- S-004 Accounts Domain — COMPLETE (1/1)
- S-005 Scan Page — COMPLETE (4/4)
- S-006 Content Domain — COMPLETE (5/5)
- S-007 Notifications — 4/5 done (T-007-05 browser-qa implementing)
- S-008 Payments — 3/4 done (T-008-04 browser-qa implementing)
- S-009 Address Autocomplete — 1/3 done (T-009-02 implementing)
- S-010 Walkthrough Fixes — 1/3 done (T-010-01 ✓, T-010-02 researching)
- S-011 First Operator Launch — 0/3 (T-011-01, T-011-02, T-011-03 all ready)
- S-012 Tenant Routing — 0/5 (T-012-01 ready; +QA T-012-05)
- S-013 Content Admin — 0/6 (T-013-01 ready; +QA T-013-06)
- S-014 CLI Onboarding — 0/3 (T-014-02 ready; +QA T-014-03)
- S-015 Self-Service Signup — 0/4 (blocked on T-012-01, T-014-01; +QA T-015-04)
- S-016 Subscription Billing — 0/4 (blocked on T-008-01 ✓ + T-013-01; +QA T-016-04)
- S-017 Custom Domains — 0/3 (blocked on T-012-01 + T-013-01 + T-016-01; +QA T-017-03)
- S-018 BAML Foundation — 0/4 (T-018-01 baml-dep-setup ready)
- S-019 Conversational Onboarding — 0/6 (blocked on T-018-03; +QA T-019-06)
- S-020 Content Generation — 0/5 (+QA T-020-05)
- S-021 QA Walkthrough Report — 0/1 (capstone: depends on all 15 browser-qa tickets, produces visual walkthrough + dev briefing)

**Epics (ongoing health):**
- E-001 Dev environment — GOOD (foundation complete, mix setup works)
- E-002 Deploy pipeline — GOOD (fly-deploy done, CI working)
- E-003 Public surface — GOOD (landing page, scan page, booking form, content pages all live)
- E-004 Domain model — GOOD (Accounts + Operations + Content domains built, tested)
- E-005 Content system — GOOD (resources, rendering, seeding, content-driven pages all done)
- E-006 First customer — PROGRESSING (all public pages live, booking creates leads, notifications nearly done, payments started)
- E-007 Demo instance — PROGRESSING (pages live, content seeded, notifications almost ready)
- E-008 Data security — PROGRESSING (tenant provisioning built, policies on resources)
- E-009 Service integrations — IN PROGRESS (notifications 4/5, payments 3/4, address 1/3)
- E-010 SaaS platform — PLANNED (3 phases: first customer → hybrid platform → self-service SaaS)
- E-011 AI onboarding — PLANNED (3 phases: BAML foundation → conversational onboarding → content generation)
