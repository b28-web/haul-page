# Project Overview — Active Status Board

> **All agents: update this file when you complete a ticket, surface a blocker, or learn something that affects other work.** This is the central information board. The developer reads this to understand what's happening without checking every ticket.

## Current state

**Phase:** Foundation (S-001) complete. Surface (S-002) complete. Phoenix 1.8.5 + Ash ecosystem running. Landing page live at `/`.

**What works:** Dev server on port 4000. Landing page renders with dark grayscale theme, Oswald/Source Sans 3 fonts, print-ready tear-off coupon layout. 11 tests passing. CI pipeline configured. Dockerfile built (278MB). Tailwind 4 + daisyUI themed.

**What's next:** Two parallel fronts are unblocked:
- **Infra chain:** T-001-05 (fly-deploy) → T-001-06 (mix-setup) — unlocks notifications, payments, address autocomplete
- **Tenancy chain:** T-004-01 (company-user-resources) — unlocks booking, content, domain model work
- **Surface chain:** T-002-02 (print-stylesheet) — unlocks scan page chain

## Active tickets

| Ticket | Title | Phase | Agent notes |
|--------|-------|-------|-------------|
| T-001-05 | fly-deploy | research | Needs: fly.toml, Fly app, Neon Postgres, DATABASE_URL secret |
| T-002-02 | print-stylesheet | design | White bg/black text print styles from React prototype |

## Ready to start (unblocked)

| Ticket | Title | Blocked by (done) |
|--------|-------|--------------------|
| T-001-05 | fly-deploy | T-001-04 ✓ |
| T-002-02 | print-stylesheet | T-002-01 ✓ |
| T-004-01 | company-user-resources | T-002-03 ✓ |

## Recently completed

| Ticket | Title | Key notes |
|--------|-------|-----------|
| T-001-01 | scaffold-phoenix | Phoenix 1.8.5 + full Ash ecosystem. Haul.Cldr for ex_money. |
| T-001-02 | version-pinning | mise.toml: Erlang 28, Elixir 1.19. CI env vars synced. |
| T-001-03 | ci-pipeline | GH Actions: test (Postgres 16) + quality (format, credo, dialyzer). |
| T-001-04 | dockerfile | Multi-stage Dockerfile, 278MB (Ash ecosystem bulk). migrate_and_start script. |
| T-002-03 | tailwind-setup | Google Fonts imported. daisyUI remapped to grayscale dark theme. @theme block. |
| T-002-01 | landing-page-markup | Four-section page at `/`. Server-rendered. Dark grayscale + print poster. 7 tests. |

## Blockers & risks

- **Dev server not responding to HTTP** — port 4000 is open (pid 14264, 10+ min uptime) but health check fails. May need restart.
- **All completed work is uncommitted** — 6 tickets worth of code in working tree, nothing committed since `12e40ee`. Risk of data loss.
- **Dockerfile image size** — 278MB vs 100MB target. Ash ecosystem is the cause. Acceptable for now but worth noting.

## Decisions made during implementation

- **No LiveView for landing page** — server-rendered via PageController, not LiveView. Keeps it simple and fast.
- **Operator config via `config.exs`** — business name, phone, email, services list hardcoded as defaults, overridable at runtime via env vars.
- **Haul.Cldr module added** — required by ex_money/ash_money. Not in original spec.
- **daisyUI themes disabled, custom grayscale themes defined** — dark/light via `[data-theme]` attribute + localStorage toggle.
- **Print layout: tear-off coupon strip** — 8 vertical coupons with phone number, designed for physical flyer use.

## Cross-ticket notes

- **Ash deps installed but unused** — ash 3.19, ash_postgres, ash_authentication, ash_state_machine, ash_oban, ash_double_entry, ash_money, ash_paper_trail, ash_archival all in mix.exs. No Ash resources defined yet. T-004-01 (company-user-resources) will be the first to use them.
- **No database migrations yet** — Repo module exists but no schemas or migrations in `priv/repo/migrations/`.
- **Test count: 11** — 7 page controller tests + 4 error handler tests. All passing.
- **`lisa` command not available** — `just lisa` recipe doesn't exist. Ticket DAG must be tracked manually or via ticket file frontmatter.
- **Browser QA tickets** (T-002-04, T-003-04, T-005-04, T-006-05, T-007-05, T-008-04, T-009-03) — all exist but are end-of-chain; none unblocked yet.

---

## Quick reference

**DAG:** 36 tickets total. 6 done, 3 unblocked/ready, 27 blocked. Max 2 concurrent.

**Chains:**
```
Infra:    T-001-01✓ → 02✓ → 03✓ → 04✓ → 05 → 06
Surface:  T-001-01✓ → T-002-03✓ → T-002-01✓ → T-002-02 → T-005-01 → 02 → 03
Tenancy:  T-002-03✓ → T-004-01 → T-003-01 → T-003-02 → T-003-03
Content:  T-004-01 → T-006-01 → 02 → 03 → 04
Notify:   T-001-06 → T-007-01,02 → 03 → 04
Payments: T-001-06 → T-008-01 → 02, 03
Address:  T-001-06 → T-009-01 → 02
```

**Stories:**
- S-001 Foundation — complete (all infra tickets through T-001-04 done)
- S-002 Landing Page — complete (T-002-01, T-002-03 done; T-002-02 print-stylesheet next)
- S-003 Booking Form — blocked on T-004-01 → T-003-01
- S-004 Accounts Domain — next up (T-004-01 unblocked)
- S-005 Scan Page — blocked on T-002-02
- S-006 Content Domain — blocked on T-004-01
- S-007 Notifications — blocked on T-001-06
- S-008 Payments — blocked on T-001-06
- S-009 Address Autocomplete — blocked on T-001-06

**Epics (ongoing health):**
- E-001 Dev environment — clone-to-running in 5 min
- E-002 Deploy pipeline — every push to main deploys
- E-003 Public surface — fast, accessible, print-ready
- E-004 Domain model — Ash resources stay correct
- E-005 Content system — schema-driven, seed-reproducible
- E-006 First customer — can we hand this to a hauler this week?
- E-007 Demo instance — live URL that sells the product
- E-008 Data security — tenant isolation tested from day one
- E-009 Service integrations — external APIs (Stripe, Twilio, Google Places)
