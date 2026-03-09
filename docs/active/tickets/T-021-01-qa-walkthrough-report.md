---
id: T-021-01
story: S-021
title: qa-walkthrough-report
type: task
status: done
priority: high
phase: done
depends_on: [T-002-04, T-003-04, T-005-04, T-006-05, T-007-05, T-008-04, T-009-03, T-012-05, T-013-06, T-014-03, T-015-04, T-016-04, T-017-03, T-019-06, T-020-05]
---

## Context

All browser-qa tickets are complete. This ticket gathers their results into a single visual walkthrough report and briefs the developer on the state of the product.

The agent running this ticket should use Playwright MCP to take fresh screenshots of the running app, AND reference the existing QA screenshots stored locally in `docs/active/work/T-*/` directories. The report is a living document the developer reads to understand "what did we build and does it work?"

## What the agent does

### 1. Gather QA results

Read every `docs/active/work/T-*-*/progress.md` file from browser-qa tickets. For each:
- Extract: ticket ID, what was tested, pass/fail, bugs found, bugs fixed
- Note any screenshots saved in the work directory

### 2. Take fresh walkthrough screenshots

Use Playwright MCP to navigate the running dev server and capture the current state. Save to `docs/active/work/T-021-01/`:

**Public pages (desktop 1280x800 + mobile 375x812):**
- `/` — landing page
- `/scan` — scan page with gallery and endorsements
- `/book` — booking form (empty state + validation state)
- `/scan/qr` — QR code output

**Admin pages (authenticated as owner):**
- `/app` — dashboard
- `/app/content/site` — site config editor
- `/app/content/services` — services list
- `/app/content/gallery` — gallery manager
- `/app/settings/billing` — subscription billing
- `/app/settings/domain` — custom domain settings

**Signup/onboarding (if implemented):**
- `/signup` — self-service signup form
- `/start` — conversational onboarding chat
- Marketing landing page on bare domain

**Print view:**
- Landing page with print media emulation

### 3. Produce the walkthrough report

Write `docs/active/work/T-021-01/walkthrough.md` — a markdown document with:

```markdown
# Product Walkthrough — [date]

## Executive summary
One paragraph: what exists, what works, what's next.

## Test results summary
| Area | ExUnit tests | Playwright QA | Status |
|------|-------------|---------------|--------|
| Landing page | X tests | T-002-04 ✓ | ... |
| ... | ... | ... | ... |

## Visual walkthrough

### Landing page
![Desktop](desktop-landing.png)
![Mobile](mobile-landing.png)
- What's here: ...
- What's tested: ...
- What's missing: ...

### Booking form
![Desktop](desktop-booking.png)
...

[repeat for each page/feature]

## Bugs found during QA
| Bug | Found in | Status | Notes |
|-----|----------|--------|-------|

## Architectural decisions
Bullet list of decisions made during implementation that the dev should know about.

## Coverage gaps
Features or pages that have no Playwright QA or thin ExUnit coverage.

## Recommendations
What the dev should look at, test manually, or prioritize next.
```

### 4. Brief the developer

After producing the report, stay in an interactive session. Present the key findings and let the developer ask questions about any page, feature, or test result.

## Acceptance Criteria

- `docs/active/work/T-021-01/walkthrough.md` exists with embedded screenshot references
- Fresh screenshots captured for every implemented page
- All browser-qa progress.md results incorporated
- Report distinguishes between "tested and passing" vs "implemented but untested" vs "not yet built"
- ExUnit test count and Playwright QA ticket count both reported
- Bugs discovered during QA are listed with resolution status
- Agent stays in interactive mode for developer Q&A after report is complete
