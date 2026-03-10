# T-025-03 Structure: Timing Verification

## Files Changed

### Test Support
| File | Change |
|------|--------|
| `test/support/factories.ex` | Rename `build_job/2` → `build_booking_job/2` |
| `test/support/conn_case.ex` | `cleanup_persistent_tenants/1` uses raw Postgrex |

### Tests Converted: setup_all → per-test setup
| File | Reason |
|------|--------|
| `test/haul/accounts/security_test.exs` | Was using setup_all switching sandbox mode |
| `test/haul/tenant_isolation_test.exs` | Same — sandbox mode race |
| `test/haul_web/live/app/dashboard_live_test.exs` | Same — sandbox mode race |

### Tests Moved to Private Tenants
| File | Reason |
|------|--------|
| `test/haul_web/live/app/billing_live_test.exs` | Mutates company (StaleRecord) |
| `test/haul_web/live/app/billing_qa_test.exs` | Same mutation issue |

### Callers Updated (build_job → build_booking_job)
| File | Change |
|------|--------|
| `test/haul/workers/send_booking_email_test.exs` | Rename call |
| `test/haul/workers/send_booking_sms_test.exs` | Rename call, remove unused alias |

## No New Files Created
All changes are edits to existing test support and test files.

## Dependencies
- No library changes
- No migration changes
- No production code changes
