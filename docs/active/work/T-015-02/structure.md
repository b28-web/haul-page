# T-015-02 Structure: Onboarding Wizard

## Files to create

### `lib/haul_web/live/app/onboarding_live.ex`
Main LiveView module (~350 lines). Single module with step state management.

**Assigns:**
- `step` — integer 1..6
- `tenant` — tenant schema string
- `site_config` — loaded SiteConfig record
- `services` — list of Service records (for display)
- `form` — AshPhoenix.Form for step 1 (site config edit)
- `uploaded_logo` — upload ref for step 4
- `company` — current company (from auth hooks)
- `base_domain` — from config
- `site_url` — computed from slug

**Events:**
- `"next"` — advance step (auto-save if applicable)
- `"back"` — previous step
- `"goto"` — jump to specific step
- `"validate"` — form validation (step 1)
- `"save_info"` — save site config (step 1)
- `"upload_logo"` — handle logo upload (step 4)
- `"remove_logo"` — remove uploaded logo
- `"go_live"` — set onboarding_complete, redirect to /app

**Render functions:**
- `render/1` — dispatches to step render function, wraps in progress bar
- `render_step/1` — pattern matches on `@step` to render appropriate step content
- `step_title/1` — returns title string for each step number
- `progress_bar/1` — horizontal step indicator component

### `priv/repo/migrations/TIMESTAMP_add_onboarding_complete_to_companies.exs`
Public migration adding `onboarding_complete` boolean to companies table.

```elixir
alter table(:companies) do
  add :onboarding_complete, :boolean, default: false, null: false
end
```

### `test/haul_web/live/app/onboarding_live_test.exs`
LiveView tests for the wizard (~150 lines).

## Files to modify

### `lib/haul/accounts/company.ex`
- Add `onboarding_complete` boolean attribute (default: false, public: true)
- Add to `:update_company` accept list

### `lib/haul_web/router.ex`
- Add `live "/onboarding", App.OnboardingLive` inside `:authenticated` live_session scope

## Module boundaries

- **OnboardingLive** — UI only. Reads SiteConfig/Service via Ash. Updates SiteConfig via AshPhoenix.Form. Updates Company via Ash.Changeset.
- **Company** — owns `onboarding_complete` field. Updated via `:update_company` action.
- **SiteConfig** — edited via existing `:edit` action in step 1.
- **Storage** — used for logo upload in step 4 (same pattern as GalleryLive).
- **Onboarding module** — `site_url/1` used for preview URL. No changes needed.

## No changes to

- Content resources (SiteConfig, Service, GalleryItem, Endorsement) — use existing actions
- Onboarding module — site_url already exists
- Auth hooks — wizard uses existing :require_auth hook
- Admin layout — wizard renders inside existing layout
- Seeder — content already seeded during signup
