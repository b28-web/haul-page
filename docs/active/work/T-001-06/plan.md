# T-001-06 Plan: mix setup

## Step 1: Write seeds.exs

Replace the placeholder `priv/repo/seeds.exs` with a functional seed script that:
- Reads operator config from `Application.get_env(:haul, :operator)`
- Logs operator name, phone, email, and service count
- Includes a clearly marked "Future seeds" section for Ash resources
- Is idempotent and safe to run multiple times

**Verify:** `mix run priv/repo/seeds.exs` prints operator info without errors.

## Step 2: Write config test

Create `test/haul/config_test.exs` that verifies:
- `:operator` config exists and has all required keys
- `business_name`, `phone`, `email` are non-empty strings
- `services` is a non-empty list with expected structure (title, description, icon)

**Verify:** `mix test test/haul/config_test.exs` passes.

## Step 3: End-to-end verification

Run the full `mix setup` alias and confirm:
- All steps complete without error
- Database is created
- Seeds run successfully
- Assets compile
- `mix phx.server` would start (verify compilation succeeds)

**Verify:** `mix setup` exits 0. `mix compile --no-start` exits 0.

## Testing strategy

- **Unit test:** `test/haul/config_test.exs` — operator config structure
- **Integration:** `mix setup` end-to-end (manual, CI covers via test alias)
- **No browser tests needed** for this ticket
