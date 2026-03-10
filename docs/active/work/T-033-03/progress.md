# T-033-03 Progress: Mock Service Layer

## Step 1: Refactor ChatSandbox for process isolation — DONE

Refactored `lib/haul/ai/chat/sandbox.ex`:
- Replaced global ETS keys (`:response`, `:error`) with PID-keyed entries (`{self(), :response}`)
- Added `$callers` ancestry chain lookup for cross-process resolution (streaming Tasks, LiveView processes)
- Removed `Process.put/get` layer (ETS with `$callers` handles both same-process and cross-process)
- All 460 stale tests pass (including all chat tests)

## Step 2: Migrate worker test cleanup to Factories — DONE

Updated 7 test files to use `Factories.cleanup_all_tenants/0`:
- test/haul/workers/check_dunning_grace_test.exs
- test/haul/workers/provision_cert_test.exs
- test/haul/workers/send_booking_email_test.exs
- test/haul/workers/send_booking_sms_test.exs
- test/haul/workers/provision_site_test.exs
- test/haul/ai/edit_applier_test.exs
- test/haul/ai/provisioner_test.exs

All 52 stale tests pass.

## Step 3: Document mocking conventions — DONE

Added "Mock the Boundary, Not Ash" section to `docs/knowledge/test-architecture.md`:
- Boundary inventory table (8 sandboxes with isolation patterns)
- Process isolation patterns explanation
- 4 rules: never mock Ash, mock at adapter boundary, keep integration tests, use Factories cleanup

## Step 4: Run full test suite — IN PROGRESS
