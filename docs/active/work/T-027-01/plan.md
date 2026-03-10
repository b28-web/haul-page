# T-027-01 Plan: Core Factories

## Steps

### Step 1: Create `test/support/factories.ex`

Extract factory functions from ConnCase into standalone module. Functions:
- `build_company/1` — from ConnCase's company creation block
- `provision_tenant/1` — from ConnCase's tenant provisioning call
- `build_user/2` — from ConnCase's user registration + role update + JWT generation
- `build_authenticated_context/1` — orchestration of the above three
- `build_admin_session/1` — from ConnCase's `create_admin_session/0`
- `cleanup_all_tenants/0` — from ConnCase's `cleanup_tenants/0`

Verify: `mix compile` succeeds.

### Step 2: Update ConnCase to delegate

Replace body of:
- `create_authenticated_context/1` → `Haul.Test.Factories.build_authenticated_context(attrs)`
- `create_admin_session/0` → `Haul.Test.Factories.build_admin_session()`
- `cleanup_tenants/0` → `Haul.Test.Factories.cleanup_all_tenants()`

Verify: targeted tests pass (pick 2-3 ConnCase test files).

### Step 3: Update SharedTenant

Change `HaulWeb.ConnCase.create_authenticated_context/1` → `Haul.Test.Factories.build_authenticated_context/1`.

Verify: `mix test test/haul_web/live/app/gallery_live_test.exs` (uses shared_test_tenant).

### Step 4: Update DataCase

Add `import Haul.Test.Factories` to `using` block.

Verify: `mix test test/haul/content/site_config_test.exs` (DataCase test, confirms import available).

### Step 5: Full suite

Run `mix test` to confirm all 845+ tests pass.

## Testing strategy

No new tests needed — this is a pure refactor. The existing 845+ tests ARE the verification. If any fail, the delegation is wrong.
