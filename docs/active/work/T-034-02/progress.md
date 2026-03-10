# T-034-02 Progress: setup_all Quick Wins

## Completed

1. **page_controller_test.exs** — Converted to setup_all. 8 tests, 0 failures. All read-only GET requests sharing one tenant + seeded content.

2. **onboarding_live_test.exs** — Converted main setup to setup_all. 20 tests, 0 failures. "Public pages after CLI onboarding" describe retains its own per-test setup (creates separate tenant via Haul.Onboarding.run/1).

3. **accounts_live_test.exs** — Converted to setup_all. 10 tests, 0 failures. Replaced inline setup_admin/create_companies with Factories. Security describe keeps per-test isolation.

4. **test-architecture.md** — Expanded setup_all section with concrete pattern, sandbox rules, and file references.

## Key learnings during implementation

- **No on_exit with mode(:auto)** — on_exit callbacks from setup_all run in separate processes and can race with the next module's sandbox setup. Solution: use `Sandbox.checkin(Repo)` after data creation, clean up stale data at the START of the next setup_all.
- **Use factories with unique names** — ConnCase's `create_authenticated_context()` uses hardcoded "Test Co" slug which collides when multiple test files commit data. `Factories.build_authenticated_context()` generates unique names.
- **superadmin_qa_test.exs was deleted** — biggest savings target no longer exists, reducing estimated savings from ~25s to ~10s.
- **impersonation_test.exs skipped** — already async:true, converting to setup_all would require async:false and likely negate savings.

## Deviations from plan

- Original ticket listed 5 files; only 3 converted (1 deleted, 1 skipped for async reasons)
- on_exit cleanup pattern changed from the design: pre-cleanup instead of post-cleanup to avoid sandbox mode races
