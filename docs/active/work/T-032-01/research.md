# T-032-01 Research: Supervised Init Tasks

## Current State

### Application.start/2 (`lib/haul/application.ex`)

Lines 27-28 call two init functions **synchronously before `Supervisor.start_link/2`**:

```elixir
Haul.Content.Loader.load!()
Haul.Admin.Bootstrap.ensure_admin!()
```

If either raises, the app crashes before the supervision tree starts. No retry, no fallback.

### Haul.Content.Loader (`lib/haul/content/loader.ex`)

- `load!/0` reads `priv/content/gallery.json` and `priv/content/endorsements.json`, parses with Jason, stores in `:persistent_term`
- `gallery_items/0` and `endorsements/0` retrieve from persistent_term
- **No `loaded?/0` function exists yet**
- **Critical finding:** `gallery_items/0` and `endorsements/0` are **never called in production code**. All content serving goes through `HaulWeb.ContentHelpers` which reads from Ash database resources, not persistent_term. The Loader's output is effectively unused.
- Only the Loader's own test file (`test/haul/content/loader_test.exs`) calls these functions
- The Loader is legacy code from T-005-02, predating the Ash content domain (T-006-xx)

### Haul.Admin.Bootstrap (`lib/haul/admin/bootstrap.ex`)

- `ensure_admin!/0` checks `ADMIN_EMAIL` env var
- Returns `:noop` if not set or empty
- Checks if AdminUser already exists (idempotent)
- Creates AdminUser with `:create_bootstrap` action if missing
- Logs setup URL on success
- **Already handles errors gracefully** — catches `{:error, _}` and returns `:noop`
- Despite the `!` name, it never actually raises. It's safe to retry.

### test_helper.exs (`test/test_helper.exs`)

- Configures ExUnit formatters and Ecto sandbox
- No explicit coordination for init tasks
- Init tasks complete synchronously before tests because `Application.start/2` blocks until they finish

### ContentHelpers (`lib/haul_web/content_helpers.ex`)

- All public-facing content routes use `ContentHelpers.load_site_config/1`, `load_services/1`, `load_gallery_items/1`, `load_endorsements/1`
- All of these query Ash resources directly (not persistent_term)
- Already has fallback logic — returns empty lists or operator config defaults on failure

### Routes that serve content

- `PageController.home/2` — uses ContentHelpers for site_config and services
- `ScanLive` — uses ContentHelpers for gallery_items and endorsements
- `BookingLive` — uses ContentHelpers for site_config
- None of these depend on `Content.Loader`

## Existing Patterns

### Retry logic

- `Haul.AI.ContentGenerator` and `Haul.AI.Extractor` use simple single-retry on transient errors
- No exponential backoff exists in the codebase
- OTP supervisors provide built-in restart with configurable strategies

### Supervision tree structure

Current children order:
1. HaulWeb.Telemetry
2. Haul.Repo
3. Oban
4. DNSCluster
5. Phoenix.PubSub
6. Haul.RateLimiter
7. HaulWeb.Endpoint

Init tasks need DB access (Repo), so they go after Repo.

## Key Constraints

1. Content Loader is effectively dead code — its persistent_term data is never read in production
2. Admin Bootstrap already handles errors gracefully (never raises)
3. Content pages already have fallback behavior via ContentHelpers
4. Test suite relies on init tasks completing before tests run
5. 845+ tests must continue to pass

## Open Questions

- Should Content Loader be removed entirely since it's unused? (Out of scope — ticket says to supervise it, not remove it)
- The ticket's AC mentions "content pages return 503 until loader succeeds" but content pages don't use the Loader. The `loaded?/0` gate would be artificial.
