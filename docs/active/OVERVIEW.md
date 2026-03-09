# Project Overview — Active Status Board

> **All agents: update this file when you complete a ticket, surface a blocker, or learn something that affects other work.** This is the central information board. The developer reads this to understand what's happening without checking every ticket.

## Current state

**Phase:** Foundation (S-001) complete. Landing page (S-002) complete. Accounts domain (S-004) complete. Scan page (S-005) complete. Booking form (S-003) nearly complete — 3/4 done. Content domain (S-006) in progress — 1/5 done, T-006-01 implementing.

**What works:** Dev server healthy on port 4000. 128 tests passing. All work committed and pushed to origin/main. Ash resources live: Accounts domain (Company, User, Token with tenant provisioning), Operations domain (Job with state machine), Content domain (SiteConfig, Service, GalleryItem, Endorsement, Page). Landing page at `/` with dark grayscale theme + print stylesheet. Scan page LiveView at `/scan` with gallery. Booking LiveView at `/book`. QR code generation. CI pipeline. Dockerfile. Fly deploy configured.

**What's next:** T-001-06 (mix-setup) done — service integration stories are unblocked:
- **Content chain:** T-006-01 (content-resources) implementing → T-006-02 → T-006-03 → T-006-04
- **Booking finish:** T-003-03 (photo-upload) in research → T-003-04 (browser-qa)
- **Service integrations now unblocked:** T-007-01/02 (swoosh/SMS), T-008-01 (stripe), T-009-01 (places proxy)

## Active tickets

| Ticket | Title | Phase | Agent notes |
|--------|-------|-------|-------------|
| T-006-01 | content-resources | implement | Content Ash domain resources being built |
| T-003-03 | photo-upload | research | Photo upload for booking form |

## Ready to start (unblocked)

| Ticket | Title | Blocked by (done) |
|--------|-------|--------------------|
| T-007-01 | swoosh-setup | T-001-06 ✓ |
| T-007-02 | sms-client | T-001-06 ✓ |
| T-008-01 | stripe-setup | T-001-06 ✓ |
| T-009-01 | places-proxy | T-001-06 ✓ |
| T-006-02 | mdex-rendering | T-006-01 (in progress) |
| T-003-04 | browser-qa | T-003-03 (in progress) |

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
| T-005-01 | scan-page-layout | Scan page LiveView at `/scan`. Dark theme, gallery, CTA. |
| T-005-02 | gallery-data | Gallery data model for before/after photos. |
| T-005-03 | qr-generation | QR code generation for scan page URL. QrController. |
| T-005-04 | browser-qa | Scan page Playwright QA passed. |

## Ready to start (unblocked) — bugfixes

| Ticket | Title | Story | Notes |
|--------|-------|-------|-------|
| T-010-01 | fix-booking-crash | S-010 | `/book` KeyError on `@max_photos` — missing assign in mount |
| T-010-02 | gallery-placeholders | S-010 | `/scan` gallery images 404 — no files in priv/static |
| T-010-03 | smoke-test | S-010 | Smoke test for all public routes (depends on T-010-01, T-010-02) |

## Blockers & risks

- **Dockerfile image size** — 278MB vs 100MB target. Ash ecosystem is the cause. Acceptable for now.

## Decisions made during implementation

- **No LiveView for landing page** — server-rendered via PageController, not LiveView.
- **Operator config via `config.exs`** — business name, phone, email, services list hardcoded as defaults, overridable at runtime via env vars.
- **Haul.Cldr module added** — required by ex_money/ash_money. Not in original spec.
- **daisyUI themes disabled, custom grayscale themes defined** — dark/light via `[data-theme]` attribute + localStorage toggle.
- **Print layout: tear-off coupon strip** — 8 vertical coupons with phone number.
- **Scan page uses LiveView** — ScanLive for dynamic gallery content.
- **Booking uses LiveView** — BookingLive with real-time validation, creates Job in :lead state.
- **Content domain resources defined** — SiteConfig, Service, GalleryItem, Endorsement, Page with Ash resources and Content.Loader.

## Cross-ticket notes

- **Ash resources now live** — Accounts (Company, User, Token), Operations (Job), Content (SiteConfig, Service, GalleryItem, Endorsement, Page). Schema-per-tenant via AshPostgres :context strategy.
- **Test count: 128** — substantial test coverage across accounts, operations, content, controllers, storage.
- **Browser QA tickets completed:** T-002-04 (landing page), T-005-04 (scan page) — both passed.
- **Remaining browser QA:** T-003-04 (booking), T-006-05 (content pages), T-007-05 (notifications), T-008-04 (payments), T-009-03 (address autocomplete).

---

## Quick reference

**DAG:** 39 tickets total. 16 done, 2 in progress, 9 ready, 12 blocked. Max 2 concurrent.

**Chains:**
```
Infra:    T-001-01✓ → 02✓ → 03✓ → 04✓ → 05✓ → 06✓  (COMPLETE)
Surface:  T-002-03✓ → T-002-01✓ → T-002-02✓ → T-002-04✓  (COMPLETE)
Scan:     T-005-01✓ → 02✓ → 03✓ → 04✓  (COMPLETE)
Tenancy:  T-004-01✓ → T-003-01✓ → T-003-02✓ → T-003-03* → T-003-04
Content:  T-004-01✓ → T-006-01* → 02 → 03 → 04 → 05
Notify:   T-001-06✓ → T-007-01,02 → 03 → 04 → 05
Payments: T-001-06✓ → T-008-01 → 02, 03 → 04
Address:  T-001-06✓ → T-009-01 → 02 → 03
Fixes:    T-010-01, T-010-02 → T-010-03
```
*in progress

**Stories:**
- S-001 Foundation — COMPLETE (6/6)
- S-002 Landing Page — COMPLETE (4/4)
- S-003 Booking Form — 3/4 done (T-003-03 photo-upload in research)
- S-004 Accounts Domain — COMPLETE (1/1)
- S-005 Scan Page — COMPLETE (4/4)
- S-006 Content Domain — 1/5 done (T-006-01 implementing)
- S-007 Notifications — 0/5 (ready to start — T-007-01, T-007-02 unblocked)
- S-008 Payments — 0/4 (ready to start — T-008-01 unblocked)
- S-009 Address Autocomplete — 0/3 (ready to start — T-009-01 unblocked)
- S-010 Walkthrough Fixes — 0/3 (bugfixes from visual walkthrough, all ready)

**Epics (ongoing health):**
- E-001 Dev environment — GOOD (foundation complete, mix setup works)
- E-002 Deploy pipeline — GOOD (fly-deploy done, CI working)
- E-003 Public surface — GOOD (landing page, scan page, booking form all live)
- E-004 Domain model — GOOD (Accounts + Operations domains built, tested)
- E-005 Content system — IN PROGRESS (resources defined, T-006-01 implementing)
- E-006 First customer — PROGRESSING (3 public pages live, booking creates leads, need notifications)
- E-007 Demo instance — PARTIAL (pages live, content system not seeded yet)
- E-008 Data security — PROGRESSING (tenant provisioning built, policies on resources)
- E-009 Service integrations — READY (all three stories unblocked, none started)
