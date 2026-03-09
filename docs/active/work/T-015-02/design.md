# T-015-02 Design: Onboarding Wizard

## Decision: Single LiveView with step state

### Options considered

**A) Separate LiveView per step** — One LiveView module per wizard step, navigate between them.
- Pro: Simple modules, easy to test individually
- Con: State lost between navigations, complex coordination, 6 modules for one feature
- Rejected: Too much overhead, state sharing is painful

**B) Single LiveView with step assigns** — One OnboardingLive with `@step` assign, render functions per step.
- Pro: All state in one place, easy step navigation, matches how signup form works
- Con: Larger module (~400 lines)
- **Chosen**: Simplest approach, proven pattern in this codebase (SignupLive handles multi-concern form)

**C) LiveComponent per step** — Single LiveView mounting step-specific LiveComponents.
- Pro: Clean separation
- Con: Over-engineered for form steps, component communication overhead
- Rejected: Complexity not justified

### Decision: Use admin layout (not standalone)

The wizard runs inside the authenticated admin layout. Reasons:
- User is already authenticated; sidebar/header provide navigation context
- If user closes wizard mid-way, they can return via sidebar or dashboard link
- Consistent with other admin pages
- Ticket says "can skip steps and come back" — sidebar nav enables this

### Decision: Subdomain step shows current slug (read-only)

Research revealed: changing the Company slug after signup requires renaming the Postgres schema (tenant_old → tenant_new). This is a destructive operation that would break existing sessions, tokens, and any stored file paths.

**Step 2 will display the current subdomain and site URL but NOT allow changes.** The slug is set correctly during signup. If a user truly needs to change it, that's a separate admin operation (not part of onboarding).

The step will show:
- Current subdomain: `{slug}.haulpage.com`
- Link to preview the site
- Note that subdomain was set during signup

### Decision: No inline service/gallery editing in wizard

Steps 3 (services) and 4 (logo) will use simplified views:
- Step 3: Show list of current services, link to full services editor (`/app/content/services`)
- Step 4: Logo upload directly in wizard (simple single-file upload)

Rationale: ServicesLive already has full CRUD with reorder, icons, modal edit. Duplicating that in the wizard is wasteful. Better to show a summary and link to the full editor.

### Decision: onboarding_complete on Company

Add `onboarding_complete` boolean to Company (default false). Set true on "Go Live" step.

Dashboard can check this field to show "Complete setup" banner if false.

The wizard remains accessible even after completion (user can revisit anytime). The field gates:
- Dashboard banner visibility
- Potential future auto-redirect from `/app` to `/app/onboarding` on first login

### Wizard steps (6 steps)

1. **Confirm Info** — Load SiteConfig, show business_name/phone/email in editable form. Save via AshPhoenix.Form + SiteConfig :edit action.
2. **Your Site** — Show current subdomain URL (read-only). Link to open site in new tab.
3. **Services** — Show list of pre-seeded services. Count + names. Link to full editor.
4. **Upload Logo** — LiveView file upload → Storage → SiteConfig.logo_url update. Optional skip.
5. **Preview** — Link to open site in new tab. Show site URL prominently.
6. **Go Live** — Confirm button. Sets Company.onboarding_complete = true. Redirect to /app.

### Progress indicator

Horizontal step indicator bar at top: circles with step numbers, filled for completed/current. CSS-only, no JS.

### Navigation

- "Next" button advances step
- "Back" button goes to previous step
- "Skip" advances without saving
- Steps auto-save on Next (where applicable — steps 1 and 4)
- Direct step clicking on progress bar allowed

### Migration

- Public migration: `add :onboarding_complete, :boolean, default: false` to companies table
- No tenant migration needed (Company is public schema)
